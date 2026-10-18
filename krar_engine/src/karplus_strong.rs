use wasm_bindgen::prelude::*;

use crate::reverb::Reverb;
use crate::string_model::StringState;

const MIX_GAIN: f32 = 0.35;

#[wasm_bindgen]
pub struct KrarEngine {
    sample_rate: u32,
    strings: Vec<StringState>,
    buffer: Vec<f32>,
    master_volume: f32,
    reverb_amount: f32,
    reverb: Reverb,
}

#[wasm_bindgen]
impl KrarEngine {
    pub fn new(sample_rate: u32, num_strings: u32) -> Self {
        let strings = (0..num_strings).map(|_| StringState::new()).collect();

        KrarEngine {
            sample_rate,
            strings,
            buffer: vec![0.0; 1024],
            master_volume: 0.8,
            reverb_amount: 0.2,
            reverb: Reverb::new(sample_rate),
        }
    }

    pub fn pluck(&mut self, string_id: u32, velocity: f32) {
        if let Some(string) = self.strings.get_mut(string_id as usize) {
            let clamped_velocity = velocity.clamp(0.0, 1.0);
            string.pluck(clamped_velocity, self.sample_rate);
        }
    }

    /// Sounds a voice with a piano hammer instead of a pluck.
    pub fn strike(&mut self, string_id: u32, velocity: f32) {
        if let Some(string) = self.strings.get_mut(string_id as usize) {
            string.strike(velocity.clamp(0.0, 1.0), self.sample_rate);
        }
    }

    pub fn release(&mut self, string_id: u32) {
        if let Some(string) = self.strings.get_mut(string_id as usize) {
            string.release();
        }
    }

    pub fn get_audio_buffer(&mut self) -> Vec<f32> {
        self.buffer.clear();

        for string in &mut self.strings {
            let string_buffer = string.process_block(128, self.sample_rate);
            for (i, &sample) in string_buffer.iter().enumerate() {
                if i < self.buffer.len() {
                    self.buffer[i] += sample;
                } else {
                    self.buffer.push(sample);
                }
            }
        }

        // Fixed headroom plus a soft clip, rather than dividing by the voice
        // count, which made everything quieter as voices were added. The
        // Schroeder tail is blended in before the clip so it stays bounded.
        let amount = self.reverb_amount;
        for sample in self.buffer.iter_mut() {
            let dry = *sample * MIX_GAIN * self.master_volume;
            let out = if amount > 0.001 {
                let wet = self.reverb.process(dry);
                dry * (1.0 - amount * 0.5) + wet * amount
            } else {
                dry
            };
            *sample = out.tanh();
        }

        self.buffer.clone()
    }

    pub fn get_string_frequency(&self, string_id: u32) -> f32 {
        self.strings
            .get(string_id as usize)
            .map(|s| s.frequency)
            .unwrap_or(0.0)
    }

    pub fn set_string_frequency(&mut self, string_id: u32, frequency: f32) {
        if let Some(string) = self.strings.get_mut(string_id as usize) {
            string.set_frequency(frequency, self.sample_rate);
        }
    }

    pub fn set_master_volume(&mut self, volume: f32) {
        self.master_volume = volume.clamp(0.0, 1.0);
    }

    pub fn get_master_volume(&self) -> f32 {
        self.master_volume
    }

    pub fn set_reverb(&mut self, amount: f32) {
        self.reverb_amount = amount.clamp(0.0, 1.0);
    }

    pub fn get_reverb(&self) -> f32 {
        self.reverb_amount
    }

    pub fn num_strings(&self) -> u32 {
        self.strings.len() as u32
    }

    pub fn get_string_config(&self, string_id: u32) -> Vec<f32> {
        if let Some(string) = self.strings.get(string_id as usize) {
            vec![
                string.frequency,
                string.velocity,
                if string.is_plucked { 1.0 } else { 0.0 },
                string.decay,
            ]
        } else {
            vec![0.0; 4]
        }
    }
}
