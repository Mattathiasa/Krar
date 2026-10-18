//! C ABI for native hosts (the iOS app calls it through `dart:ffi`).
//!
//! The engine renders straight into CoreAudio on cpal's real-time thread.
//! Control calls share the engine through a mutex; the audio callback only
//! ever `try_lock`s, so it outputs one silent block rather than wait.

use std::sync::{Mutex, OnceLock};

use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};

use crate::karplus_strong::KrarEngine;

const WAVE_LEN: usize = 1024;

struct Shared {
    engine: KrarEngine,
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
    let Some(device) = host.default_output_device() else {
        return -1;
    };
    let Ok(config) = device.default_output_config() else {
        return -2;
    };
    if config.sample_format() != cpal::SampleFormat::F32 {
        return -2;
    }
    let sample_rate = config.sample_rate().0;
    let channels = config.channels() as usize;

    let shared = SHARED.get_or_init(|| {
        Mutex::new(Shared {
            engine: KrarEngine::new(sample_rate, num_voices),
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

#[no_mangle]
pub extern "C" fn krar_set_string_frequency(string_id: u32, frequency: f32) {
    with_engine((), |s| s.engine.set_string_frequency(string_id, frequency));
}

#[no_mangle]
pub extern "C" fn krar_set_master_volume(volume: f32) {
    with_engine((), |s| s.engine.set_master_volume(volume));
}

#[no_mangle]
pub extern "C" fn krar_set_reverb(amount: f32) {
    with_engine((), |s| s.engine.set_reverb(amount));
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
