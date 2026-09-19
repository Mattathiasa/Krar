use wasm_bindgen::prelude::*;
use std::collections::HashMap;

use crate::scale::ScaleType;
use crate::string_model::StringState;

#[wasm_bindgen]
pub struct KrarEngine {
    sample_rate: u32,
    strings: Vec<StringState>,
    active_scale: ScaleType,
    buffer: Vec<f32>,
    note_frequencies: HashMap<String, f32>,
    master_volume: f32,
    reverb_amount: f32,
}

#[wasm_bindgen]
impl KrarEngine {
    pub fn new(sample_rate: u32, num_strings: u32) -> Self {
        let strings = (0..num_strings)
            .map(|_| StringState::new())
            .collect();

        let mut engine = KrarEngine {
            sample_rate,
            strings,
            active_scale: ScaleType::TizitaMinor,
            buffer: vec![0.0; 1024],
            note_frequencies: HashMap::new(),
            master_volume: 0.8,
            reverb_amount: 0.2,
        };

        engine.init_note_frequencies();
        engine
    }

    pub fn pluck(&mut self, string_id: u32, velocity: f32) {
        if let Some(string) = self.strings.get_mut(string_id as usize) {
            let clamped_velocity = velocity.clamp(0.0, 1.0);
            string.pluck(clamped_velocity, self.sample_rate);
        }
    }

    pub fn release(&mut self, string_id: u32) {
        if let Some(string) = self.strings.get_mut(string_id as usize) {
            string.release();
        }
    }

    pub fn set_scale(&mut self, scale_type: ScaleType) {
        self.active_scale = scale_type;
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

        let num_strings = self.strings.len() as f32;
        if num_strings > 0.0 {
            for sample in self.buffer.iter_mut() {
                *sample = (*sample / num_strings) * self.master_volume;
            }
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

    fn init_note_frequencies(&mut self) {
        let notes = [
            ("C2", 65.41), ("D2", 73.42), ("E2", 82.41), ("F2", 87.31),
            ("G2", 98.00), ("A2", 110.00), ("B2", 123.47),
            ("C3", 130.81), ("D3", 146.83), ("E3", 164.81), ("F3", 174.61),
            ("G3", 196.00), ("A3", 220.00), ("B3", 246.94),
            ("C4", 261.63), ("D4", 293.66), ("E4", 329.63), ("F4", 349.23),
            ("G4", 392.00), ("A4", 440.00), ("B4", 493.88),
        ];

        for (note, freq) in notes {
            self.note_frequencies.insert(note.to_string(), freq as f32);
        }
    }
}
