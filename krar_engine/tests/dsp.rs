use krar_engine::{KrarEngine, StringState};

const SAMPLE_RATE: u32 = 48000;
const BLOCK: usize = 128;

fn process_n(s: &mut StringState, blocks: usize) -> Vec<f32> {
    let mut out = Vec::with_capacity(blocks * BLOCK);
    for _ in 0..blocks {
        out.extend(s.process_block(BLOCK, SAMPLE_RATE));
    }
    out
}

/// Dominant frequency via autocorrelation, which is robust to the noise burst
/// that starts a Karplus-Strong note.
fn dominant_frequency(signal: &[f32], sample_rate: u32) -> f32 {
    let n = signal.len();
    let mean = signal.iter().sum::<f32>() / n as f32;
    let signal: Vec<f32> = signal.iter().map(|s| s - mean).collect();

    let min_lag = (sample_rate as f32 / 1000.0) as usize; // 1 kHz ceiling
    let max_lag = (sample_rate as f32 / 50.0) as usize; // 50 Hz floor
    let limit = (n / 2).min(max_lag);

    let mut best_lag = min_lag;
    let mut best_corr = f32::MIN;
    for lag in min_lag..limit {
        let mut corr = 0.0;
        for i in 0..(n - lag) {
            corr += signal[i] * signal[i + lag];
        }
        if corr > best_corr {
            best_corr = corr;
            best_lag = lag;
        }
    }

    sample_rate as f32 / best_lag as f32
}

fn peak(signal: &[f32]) -> f32 {
    signal.iter().fold(0.0f32, |m, s| m.max(s.abs()))
}

/// RMS over a window, a steadier amplitude measure than a single peak.
fn rms(signal: &[f32]) -> f32 {
    (signal.iter().map(|s| s * s).sum::<f32>() / signal.len() as f32).sqrt()
}

#[test]
fn string_plucks_at_configured_frequency() {
    let mut s = StringState::new();
    s.set_frequency(220.0, SAMPLE_RATE);
    s.pluck(1.0, SAMPLE_RATE);

    let signal = process_n(&mut s, 40);
    let f0 = dominant_frequency(&signal[..4096], SAMPLE_RATE);
    assert!((f0 - 220.0).abs() < 3.0, "expected ~220 Hz, got {f0}");
}

#[test]
fn string_pitch_tracks_frequency_changes() {
    let mut s = StringState::new();
    s.set_frequency(440.0, SAMPLE_RATE);
    s.pluck(1.0, SAMPLE_RATE);

    // Retune mid-note; Karplus-Strong changes pitch on the next pass.
    s.set_frequency(330.0, SAMPLE_RATE);
    let signal = process_n(&mut s, 40);
    let f0 = dominant_frequency(&signal[..4096], SAMPLE_RATE);
    assert!((f0 - 330.0).abs() < 4.0, "expected ~330 Hz, got {f0}");
}

#[test]
fn pluck_decays_over_time() {
    let mut s = StringState::new();
    s.set_frequency(220.0, SAMPLE_RATE);
    s.pluck(1.0, SAMPLE_RATE);

    // ~4 seconds: the envelope half-life is ~0.29 s, so this is several
    // half-lives and the tail must be far quieter than the attack.
    let signal = process_n(&mut s, 1500);
    let first = rms(&signal[..SAMPLE_RATE as usize]);
    let last = rms(&signal[signal.len() - SAMPLE_RATE as usize..]);
    assert!(
        last < first * 0.1,
        "string should decay: first rms={first}, last rms={last}"
    );
}

#[test]
fn strike_has_no_dc_offset() {
    let mut s = StringState::new();
    s.set_frequency(261.63, SAMPLE_RATE);
    s.strike(1.0, SAMPLE_RATE);

    // The hammer bump is lopsided, so without DC removal Karplus-Strong
    // would hold the offset forever. Sample a few whole periods.
    let signal = process_n(&mut s, 6);
    let mean = signal.iter().sum::<f32>() / signal.len() as f32;
    assert!(
        mean.abs() < 0.5 * peak(&signal) * 0.05,
        "strike output should be DC-free, mean={mean}, peak={}",
        peak(&signal)
    );
}

#[test]
fn strike_rings_longer_than_pluck() {
    let mut plucked = StringState::new();
    plucked.set_frequency(261.63, SAMPLE_RATE);
    plucked.pluck(1.0, SAMPLE_RATE);

    let mut struck = StringState::new();
    struck.set_frequency(261.63, SAMPLE_RATE);
    struck.strike(1.0, SAMPLE_RATE);

    let mut plucked_signal = Vec::new();
    let mut struck_signal = Vec::new();
    for _ in 0..1500 {
        plucked_signal.extend(plucked.process_block(BLOCK, SAMPLE_RATE));
        struck_signal.extend(struck.process_block(BLOCK, SAMPLE_RATE));
    }

    // After ~4 s the piano string (slower decay) must still be ringing
    // clearly longer than the plucked gut string.
    let tail = |sig: &[f32]| rms(&sig[sig.len() - SAMPLE_RATE as usize..]);
    assert!(
        tail(&struck_signal) > tail(&plucked_signal) * 2.0,
        "piano strings should sustain longer: struck={}, plucked={}",
        tail(&struck_signal),
        tail(&plucked_signal)
    );
}

#[test]
fn idle_string_is_silent() {
    let mut s = StringState::new();
    s.set_frequency(220.0, SAMPLE_RATE);
    let out = s.process_block(BLOCK, SAMPLE_RATE);
    assert_eq!(
        peak(&out),
        0.0,
        "an un-plucked string should output silence"
    );
}

#[test]
fn louder_plucks_are_louder() {
    let level = |velocity: f32| {
        let mut s = StringState::new();
        s.set_frequency(220.0, SAMPLE_RATE);
        s.pluck(velocity, SAMPLE_RATE);
        let signal = process_n(&mut s, 4);
        rms(&signal)
    };

    let loud = level(1.0);
    let quiet = level(0.3);
    assert!(
        loud > quiet * 2.0,
        "velocity should scale amplitude: loud={loud}, quiet={quiet}"
    );
}

#[test]
fn engine_is_silent_before_any_note() {
    let mut engine = KrarEngine::new(SAMPLE_RATE, 5);
    for i in 0..5 {
        engine.set_string_frequency(i, 220.0);
    }
    for _ in 0..10 {
        assert_eq!(peak(&engine.get_audio_buffer()), 0.0);
    }
}

#[test]
fn engine_pluck_produces_sound() {
    let mut engine = KrarEngine::new(SAMPLE_RATE, 5);
    for i in 0..5 {
        engine.set_string_frequency(i, 220.0);
    }
    engine.pluck(2, 1.0);

    let mut signal = Vec::new();
    for _ in 0..10 {
        signal.extend(engine.get_audio_buffer());
    }
    assert!(peak(&signal) > 0.01, "pluck should produce audible output");
}

#[test]
fn engine_output_stays_bounded() {
    let mut engine = KrarEngine::new(SAMPLE_RATE, 14);
    for i in 0..14 {
        engine.set_string_frequency(i, 69.0 + i as f32 * 30.0);
    }

    // Hammer every voice at once; the tanh soft-clip must keep this in range.
    for i in 0..14 {
        engine.strike(i, 1.0);
    }

    for _ in 0..50 {
        for sample in engine.get_audio_buffer() {
            assert!(sample.abs() <= 1.0, "mixed output must stay in [-1, 1]");
        }
    }
}

#[test]
fn master_volume_scales_output() {
    let level = |volume: f32| {
        let mut e = KrarEngine::new(SAMPLE_RATE, 1);
        e.set_string_frequency(0, 220.0);
        e.set_master_volume(volume);
        e.pluck(0, 1.0);
        peak(&e.get_audio_buffer())
    };

    let loud = level(1.0);
    let quiet = level(0.1);
    assert!(
        loud > quiet * 5.0,
        "master volume should scale output: loud={loud}, quiet={quiet}"
    );
}

#[test]
fn out_of_range_voices_are_ignored() {
    let mut engine = KrarEngine::new(SAMPLE_RATE, 5);
    engine.pluck(99, 1.0);
    engine.strike(99, 1.0);
    engine.release(99);
    engine.set_string_frequency(99, 440.0);
    assert_eq!(engine.get_string_frequency(99), 0.0);
    assert_eq!(engine.num_strings(), 5);
}
