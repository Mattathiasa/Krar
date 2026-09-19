use std::sync::atomic::{AtomicU32, Ordering};

use wasm_bindgen::prelude::*;

/// Per-sample envelope decay after a pluck. 0.999 died out in ~60 ms;
/// this lets a string ring for a few seconds like gut on a lyre.
const ENVELOPE_DECAY: f32 = 0.99995;

/// Energy kept on each pass round the delay line (Karplus-Strong loop gain).
const LOOP_GAIN: f32 = 0.996;

static NOISE_STATE: AtomicU32 = AtomicU32::new(0x9E37_79B9);

/// Uniform noise in [-1, 1) from a xorshift generator, so the pluck burst
/// works the same in WASM and in native builds.
fn noise() -> f32 {
    let mut x = NOISE_STATE.load(Ordering::Relaxed);
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    NOISE_STATE.store(x, Ordering::Relaxed);
    (x as f32 / u32::MAX as f32) * 2.0 - 1.0
}

#[wasm_bindgen]
pub struct StringConfig {
    id: u32,
    name: String,
    frequency: f32,
    tension: f32,
    length: f32,
    mass: f32,
    damping: f32,
}

#[wasm_bindgen]
impl StringConfig {
    pub fn new(id: u32, name: &str, frequency: f32) -> Self {
        StringConfig {
            id,
            name: name.to_string(),
            frequency,
            tension: 1.0,
            length: 1.0,
            mass: 0.01,
            damping: 0.001,
        }
    }

    pub fn begena_string(id: u32, name: &str, frequency: f32) -> Self {
        StringConfig {
            id,
            name: name.to_string(),
            frequency,
            tension: 0.8,
            length: 0.9,
            mass: 0.012,
            damping: 0.0015,
        }
    }

    pub fn name(&self) -> String {
        self.name.clone()
    }

    pub fn frequency(&self) -> f32 {
        self.frequency
    }

    pub fn tension(&self) -> f32 {
        self.tension
    }

    pub fn damping(&self) -> f32 {
        self.damping
    }
}

#[wasm_bindgen]
pub struct StringState {
    pub frequency: f32,
    pub velocity: f32,
    pub is_plucked: bool,
    buffer: Vec<f32>,
    buffer_index: usize,
    pub decay: f32,
    pub phase: f32,
    harmonics: Vec<f32>,
    harmonic_damping: Vec<f32>,
}

#[wasm_bindgen]
impl StringState {
    pub fn new() -> Self {
        let harmonics = vec![1.0, 0.8, 0.6, 0.4, 0.3, 0.2, 0.15, 0.1];
        let harmonic_damping = vec![0.999, 0.998, 0.997, 0.996, 0.995, 0.994, 0.993, 0.992];

        StringState {
            frequency: 440.0,
            velocity: 0.0,
            is_plucked: false,
            buffer: vec![0.0; 1024],
            buffer_index: 0,
            decay: ENVELOPE_DECAY,
            phase: 0.0,
            harmonics,
            harmonic_damping,
        }
    }

    pub fn pluck(&mut self, velocity: f32, sample_rate: u32) {
        self.velocity = velocity;
        self.is_plucked = true;

        let buffer_length = (sample_rate as f32 / self.frequency) as usize;
        self.buffer.resize(buffer_length, 0.0);

        for i in 0..buffer_length {
            let mut sample = 0.0;
            for (h, &harmonic_amp) in self.harmonics.iter().enumerate() {
                let harmonic_freq = self.frequency * (h + 1) as f32;
                let phase = (i as f32 / sample_rate as f32) * harmonic_freq * 2.0 * std::f32::consts::PI;
                sample += phase.sin() * harmonic_amp * noise();
            }
            self.buffer[i] = sample * velocity * 0.25;
        }

        self.buffer_index = 0;
        self.decay = ENVELOPE_DECAY;
    }

    pub fn release(&mut self) {
        self.is_plucked = false;
    }

    pub fn set_frequency(&mut self, frequency: f32, sample_rate: u32) {
        self.frequency = frequency;
        let buffer_length = (sample_rate as f32 / frequency) as usize;
        self.buffer.resize(buffer_length, 0.0);
    }

    pub fn process_block(&mut self, block_size: usize, _sample_rate: u32) -> Vec<f32> {
        let mut output = vec![0.0; block_size];

        if !self.is_plucked && self.velocity < 0.001 {
            return output;
        }

        for i in 0..block_size {
            let current_sample = self.buffer[self.buffer_index];
            let next_index = (self.buffer_index + 1) % self.buffer.len();
            let next_sample = self.buffer[next_index];

            let averaged = (current_sample + next_sample) * 0.5;
            let filtered = averaged * LOOP_GAIN;

            self.buffer[self.buffer_index] = filtered;

            output[i] = current_sample * self.velocity;

            self.buffer_index = next_index;

            self.velocity *= self.decay;
        }

        output
    }

    pub fn get_harmonics(&self) -> Vec<f32> {
        self.harmonics.clone()
    }

    pub fn set_harmonics(&mut self, harmonics: Vec<f32>) {
        self.harmonics = harmonics;
    }
}

impl Default for StringState {
    fn default() -> Self {
        StringState::new()
    }
}
