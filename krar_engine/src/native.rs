//! C ABI for native hosts (the iOS app calls it through `dart:ffi`).
//!
//! Unlike the web build, where the page pulls blocks from the engine, here
//! the engine renders straight into CoreAudio on cpal's real-time thread.
//! Control calls share the engine through a mutex; the audio callback only
//! ever `try_lock`s, so it outputs one silent block rather than wait.

use std::sync::{Mutex, OnceLock};

use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};

use crate::karplus_strong::KrarEngine;
use crate::scale::ScaleType;

const WAVE_LEN: usize = 1024;

struct Shared {
    engine: KrarEngine,
    sample_rate: u32,
    block: Vec<f32>,
    pos: usize,
    wave: [f32; WAVE_LEN],
    wave_pos: usize,
}

impl Shared {
    fn next_sample(&mut self) -> f32 {
        if self.pos >= self.block.len() {
            self.block = self.engine.get_audio_buffer();
            self.pos = 0;
        }
        let s = self.block[self.pos];
        self.pos += 1;
        self.wave[self.wave_pos] = s;
        self.wave_pos = (self.wave_pos + 1) % WAVE_LEN;
        s
    }
}

static SHARED: OnceLock<Mutex<Shared>> = OnceLock::new();

fn with_engine<R>(default: R, f: impl FnOnce(&mut Shared) -> R) -> R {
    match SHARED.get() {
        Some(m) => match m.lock() {
            Ok(mut g) => f(&mut g),
            Err(_) => default,
        },
        None => default,
    }
}

/// Starts audio output with `num_voices` strings. Safe to call again.
/// Returns 0 on success, or a negative code: -1 no output device,
/// -2 no usable config, -3 stream failed to build, -4 stream failed to play.
#[no_mangle]
pub extern "C" fn krar_start(num_voices: u32) -> i32 {
    if SHARED.get().is_some() {
        return 0;
    }
    let host = cpal::default_host();
    let Some(device) = host.default_output_device() else { return -1 };
    let Ok(config) = device.default_output_config() else { return -2 };
    if config.sample_format() != cpal::SampleFormat::F32 {
        return -2;
    }
    let sample_rate = config.sample_rate().0;
    let channels = config.channels() as usize;

    let shared = SHARED.get_or_init(|| {
        Mutex::new(Shared {
            engine: KrarEngine::new(sample_rate, num_voices),
            sample_rate,
            block: Vec::new(),
            pos: 0,
            wave: [0.0; WAVE_LEN],
            wave_pos: 0,
        })
    });

    let stream = device.build_output_stream(
        &config.into(),
        move |data: &mut [f32], _| match shared.try_lock() {
            Ok(mut g) => {
                for frame in data.chunks_mut(channels) {
                    let s = g.next_sample();
                    frame.fill(s);
                }
            }
            Err(_) => data.fill(0.0),
        },
        |err| eprintln!("krar_engine audio stream error: {err}"),
        None,
    );
    let Ok(stream) = stream else { return -3 };
    if stream.play().is_err() {
        return -4;
    }
    // Audio runs for the life of the app.
    std::mem::forget(stream);
    0
}

#[no_mangle]
pub extern "C" fn krar_sample_rate() -> u32 {
    with_engine(0, |s| s.sample_rate)
}

#[no_mangle]
pub extern "C" fn krar_pluck(string_id: u32, velocity: f32) {
    with_engine((), |s| s.engine.pluck(string_id, velocity));
}

#[no_mangle]
pub extern "C" fn krar_strike(string_id: u32, velocity: f32) {
    with_engine((), |s| s.engine.strike(string_id, velocity));
}

#[no_mangle]
pub extern "C" fn krar_release(string_id: u32) {
    with_engine((), |s| s.engine.release(string_id));
}

/// 0 Tizita Minor, 1 Tizita Major, 2 Ambassel, 3 Bati.
#[no_mangle]
pub extern "C" fn krar_set_scale(scale: u32) {
    let scale = match scale {
        1 => ScaleType::TizitaMajor,
        2 => ScaleType::Ambassel,
        3 => ScaleType::Bati,
        _ => ScaleType::TizitaMinor,
    };
    with_engine((), |s| s.engine.set_scale(scale));
}

#[no_mangle]
pub extern "C" fn krar_set_string_frequency(string_id: u32, frequency: f32) {
    with_engine((), |s| s.engine.set_string_frequency(string_id, frequency));
}

#[no_mangle]
pub extern "C" fn krar_get_string_frequency(string_id: u32) -> f32 {
    with_engine(0.0, |s| s.engine.get_string_frequency(string_id))
}

#[no_mangle]
pub extern "C" fn krar_set_master_volume(volume: f32) {
    with_engine((), |s| s.engine.set_master_volume(volume));
}

#[no_mangle]
pub extern "C" fn krar_get_master_volume() -> f32 {
    with_engine(0.0, |s| s.engine.get_master_volume())
}

#[no_mangle]
pub extern "C" fn krar_set_reverb(amount: f32) {
    with_engine((), |s| s.engine.set_reverb(amount));
}

#[no_mangle]
pub extern "C" fn krar_get_reverb() -> f32 {
    with_engine(0.0, |s| s.engine.get_reverb())
}

/// Writes [frequency, velocity, is_plucked, decay] for one string into `out` (4 floats).
///
/// # Safety
/// `out` must point to at least 4 writable f32s.
#[no_mangle]
pub unsafe extern "C" fn krar_string_config(string_id: u32, out: *mut f32) {
    if out.is_null() {
        return;
    }
    let cfg = with_engine(vec![0.0; 4], |s| s.engine.get_string_config(string_id));
    std::ptr::copy_nonoverlapping(cfg.as_ptr(), out, 4.min(cfg.len()));
}

/// Copies the most recent `len` output samples, oldest first, into `out`.
/// Returns how many were written.
///
/// # Safety
/// `out` must point to at least `len` writable f32s.
#[no_mangle]
pub unsafe extern "C" fn krar_copy_waveform(out: *mut f32, len: u32) -> u32 {
    if out.is_null() {
        return 0;
    }
    let n = (len as usize).min(WAVE_LEN);
    with_engine(0, |s| {
        let start = (s.wave_pos + WAVE_LEN - n) % WAVE_LEN;
        for i in 0..n {
            *out.add(i) = s.wave[(start + i) % WAVE_LEN];
        }
        n as u32
    })
}
