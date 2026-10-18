use wasm_bindgen::prelude::*;

mod karplus_strong;
mod reverb;
mod string_model;

#[cfg(not(target_arch = "wasm32"))]
pub mod native;

pub use karplus_strong::KrarEngine;
pub use string_model::StringState;

#[wasm_bindgen]
pub fn create_engine(sample_rate: u32, num_strings: u32) -> KrarEngine {
    KrarEngine::new(sample_rate, num_strings)
}
