use wasm_bindgen::prelude::*;

mod karplus_strong;
mod scale;
mod string_model;

pub use karplus_strong::KrarEngine;
pub use scale::{Scale, ScaleType};
pub use string_model::StringConfig;

#[wasm_bindgen]
pub fn create_engine(sample_rate: u32, num_strings: u32) -> KrarEngine {
    KrarEngine::new(sample_rate, num_strings)
}
