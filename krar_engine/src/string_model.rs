use wasm_bindgen::prelude::*;

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
}

#[wasm_bindgen]
impl StringState {
    pub fn new() -> Self {
        StringState {
            frequency: 440.0,
            velocity: 0.0,
            is_plucked: false,
            buffer: vec![0.0; 1024],
            buffer_index: 0,
            decay: 0.999,
            phase: 0.0,
        }
    }

    pub fn pluck(&mut self, velocity: f32, sample_rate: u32) {
        self.velocity = velocity;
        self.is_plucked = true;

        let buffer_length = (sample_rate as f32 / self.frequency) as usize;
        self.buffer.resize(buffer_length, 0.0);

        for i in 0..buffer_length {
            self.buffer[i] = (js_sys::Math::random() as f32 * 2.0 - 1.0) * velocity;
        }

        self.buffer_index = 0;
        self.decay = 0.999;
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
            let filtered = averaged * 0.97;

            self.buffer[self.buffer_index] = filtered;

            output[i] = current_sample * self.velocity;

            self.buffer_index = next_index;

            self.velocity *= self.decay;
        }

        output
    }
}

impl Default for StringState {
    fn default() -> Self {
        StringState::new()
    }
}
