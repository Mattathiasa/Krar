/// A small Schroeder reverb: four parallel comb filters into two allpasses.
/// Cheap, stable, and good enough for a wooden chamber around a lyre.
pub struct Reverb {
    combs: [Comb; 4],
    allpasses: [Allpass; 2],
}

struct Comb {
    buffer: Vec<f32>,
    index: usize,
    feedback: f32,
    damp: f32,
    filter_state: f32,
}

impl Comb {
    fn new(delay: usize, feedback: f32, damp: f32) -> Self {
        Comb {
            buffer: vec![0.0; delay],
            index: 0,
            feedback,
            damp,
            filter_state: 0.0,
        }
    }

    fn process(&mut self, input: f32) -> f32 {
        let output = self.buffer[self.index];
        // Low-pass in the feedback loop so the tail darkens as it decays.
        self.filter_state = output * (1.0 - self.damp) + self.filter_state * self.damp;
        self.buffer[self.index] = input + self.filter_state * self.feedback;
        self.index = (self.index + 1) % self.buffer.len();
        output
    }
}

struct Allpass {
    buffer: Vec<f32>,
    index: usize,
    gain: f32,
}

impl Allpass {
    fn new(delay: usize, gain: f32) -> Self {
        Allpass {
            buffer: vec![0.0; delay],
            index: 0,
            gain,
        }
    }

    fn process(&mut self, input: f32) -> f32 {
        let buffered = self.buffer[self.index];
        let output = -input + buffered;
        self.buffer[self.index] = input + buffered * self.gain;
        self.index = (self.index + 1) % self.buffer.len();
        output
    }
}

impl Reverb {
    pub fn new(sample_rate: u32) -> Self {
        let ms = |t: f32| (sample_rate as f32 * t / 1000.0) as usize;
        Reverb {
            // Four combs tuned to mutually prime lengths to avoid a metallic
            // ring; feedback gives roughly a two-second decay.
            combs: [
                Comb::new(ms(29.7), 0.88, 0.25),
                Comb::new(ms(37.1), 0.88, 0.25),
                Comb::new(ms(41.1), 0.88, 0.25),
                Comb::new(ms(43.7), 0.88, 0.25),
            ],
            allpasses: [Allpass::new(ms(5.0), 0.5), Allpass::new(ms(1.7), 0.5)],
        }
    }

    /// One sample through the network. Input is pre-mixed audio, output is
    /// the wet tail only; the caller blends it back over the dry signal.
    pub fn process(&mut self, input: f32) -> f32 {
        let mut wet = 0.0;
        for comb in &mut self.combs {
            wet += comb.process(input);
        }
        wet *= 0.25;
        for allpass in &mut self.allpasses {
            wet = allpass.process(wet);
        }
        wet
    }
}
