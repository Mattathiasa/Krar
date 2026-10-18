use wasm_bindgen::prelude::*;

#[wasm_bindgen]
#[derive(Clone, Copy, PartialEq, Debug)]
pub enum ScaleType {
    TizitaMinor,
    TizitaMajor,
    Ambassel,
    Bati,
}

/// A qenet. The cent table is the single source of truth: interval ratios are
/// derived from it, so the two can never disagree (Bati used to).
#[wasm_bindgen]
pub struct Scale {
    scale_type: ScaleType,
    name: String,
    cents: Vec<f32>,
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
                description: "Traditional Ethiopian scale with minor character".to_string(),
            },
            ScaleType::TizitaMajor => Scale {
                scale_type,
                name: "Tizita Major".to_string(),
                cents: vec![0.0, 282.0, 386.0, 520.0, 678.0, 884.0, 1018.0, 1136.0],
                description: "Major variant of the Tizita scale".to_string(),
            },
            ScaleType::Ambassel => Scale {
                scale_type,
                name: "Ambassel".to_string(),
                cents: vec![0.0, 182.0, 316.0, 520.0, 678.0, 812.0, 1018.0, 1136.0],
                description: "Melancholic Ethiopian scale".to_string(),
            },
            ScaleType::Bati => Scale {
                scale_type,
                name: "Bati".to_string(),
                cents: vec![0.0, 182.0, 316.0, 498.0, 678.0, 884.0, 1018.0, 1136.0],
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
        match self.cents.get(degree as usize) {
            Some(&c) => root_freq * 2f32.powf(c / 1200.0),
            None => root_freq,
        }
    }

    pub fn get_cents(&self, degree: u32) -> f32 {
        self.cents.get(degree as usize).copied().unwrap_or(0.0)
    }

    pub fn num_degrees(&self) -> u32 {
        self.cents.len() as u32
    }

    pub fn get_all_intervals(&self) -> Vec<f32> {
        self.cents.iter().map(|&c| 2f32.powf(c / 1200.0)).collect()
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn intervals_are_derived_from_cents() {
        for st in [
            ScaleType::TizitaMinor,
            ScaleType::TizitaMajor,
            ScaleType::Ambassel,
            ScaleType::Bati,
        ] {
            let scale = Scale::new(st);
            let cents = scale.get_all_cents();
            let intervals = scale.get_all_intervals();
            for (c, i) in cents.iter().zip(&intervals) {
                assert_eq!(*i, 2f32.powf(c / 1200.0));
            }
            // Degree frequencies agree with the cent table by construction.
            for (d, c) in cents.iter().enumerate() {
                let f = scale.get_frequency_from_root(200.0, d as u32);
                assert_eq!(f, 200.0 * 2f32.powf(c / 1200.0));
            }
        }
    }

    #[test]
    fn bati_degree_three_is_498_cents() {
        // Bati's old hand-written interval table said 1.337 (~520 cents) for
        // this degree, contradicting its own cent table.
        let scale = Scale::new(ScaleType::Bati);
        assert_eq!(scale.get_cents(3), 498.0);
        let interval = scale.get_all_intervals()[3];
        assert!((interval - 2f32.powf(498.0 / 1200.0)).abs() < 1e-6);
        assert!((interval - 1.333).abs() < 0.001, "got {interval}");
    }
}
