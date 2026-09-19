use wasm_bindgen::prelude::*;

#[wasm_bindgen]
#[derive(Clone, Copy, PartialEq, Debug)]
pub enum ScaleType {
    TizitaMinor,
    TizitaMajor,
    Ambassel,
    Bati,
}

#[wasm_bindgen]
pub struct Scale {
    scale_type: ScaleType,
    name: String,
    cents: Vec<f32>,
    intervals: Vec<f32>,
    description: String,
}

#[wasm_bindgen]
impl Scale {
    pub fn new(scale_type: ScaleType) -> Self {
        match scale_type {
            ScaleType::TizitaMinor => Scale {
                scale_type,
                name: "Tizita Minor".to_string(),
                cents: vec![0.0, 282.0, 386.0, 520.0, 678.0, 884.0, 1018.0, 1136.0],
                intervals: vec![1.0, 1.189, 1.261, 1.337, 1.417, 1.500, 1.587, 1.682],
                description: "Traditional Ethiopian scale with minor character".to_string(),
            },
            ScaleType::TizitaMajor => Scale {
                scale_type,
                name: "Tizita Major".to_string(),
                cents: vec![0.0, 282.0, 386.0, 520.0, 678.0, 884.0, 1018.0, 1136.0],
                intervals: vec![1.0, 1.189, 1.261, 1.337, 1.417, 1.500, 1.587, 1.682],
                description: "Major variant of the Tizita scale".to_string(),
            },
            ScaleType::Ambassel => Scale {
                scale_type,
                name: "Ambassel".to_string(),
                cents: vec![0.0, 182.0, 316.0, 520.0, 678.0, 812.0, 1018.0, 1136.0],
                intervals: vec![1.0, 1.107, 1.199, 1.337, 1.417, 1.500, 1.587, 1.682],
                description: "Melancholic Ethiopian scale".to_string(),
            },
            ScaleType::Bati => Scale {
                scale_type,
                name: "Bati".to_string(),
                cents: vec![0.0, 182.0, 316.0, 498.0, 678.0, 884.0, 1018.0, 1136.0],
                intervals: vec![1.0, 1.107, 1.199, 1.337, 1.417, 1.500, 1.587, 1.682],
                description: "Bright Ethiopian scale".to_string(),
            },
        }
    }

    pub fn name(&self) -> String {
        self.name.clone()
    }

    pub fn description(&self) -> String {
        self.description.clone()
    }

    pub fn get_frequency_from_root(&self, root_freq: f32, degree: u32) -> f32 {
        if let Some(&interval) = self.intervals.get(degree as usize) {
            root_freq * interval
        } else {
            root_freq
        }
    }

    pub fn get_cents(&self, degree: u32) -> f32 {
        self.cents.get(degree as usize).copied().unwrap_or(0.0)
    }

    pub fn num_degrees(&self) -> u32 {
        self.cents.len() as u32
    }

    pub fn get_all_intervals(&self) -> Vec<f32> {
        self.intervals.clone()
    }

    pub fn get_all_cents(&self) -> Vec<f32> {
        self.cents.clone()
    }

    pub fn scale_type(&self) -> ScaleType {
        self.scale_type
    }
}

impl Default for Scale {
    fn default() -> Self {
        Scale::new(ScaleType::TizitaMinor)
    }
}
