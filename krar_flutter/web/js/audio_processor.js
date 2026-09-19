class KrarProcessor extends AudioWorkletProcessor {
  constructor() {
    super();
    this.buffer = new Float32Array(128);
    this.bufferIndex = 0;
    this.isRunning = false;

    this.port.onmessage = (event) => {
      if (event.data.type === 'buffer') {
        this.buffer = new Float32Array(event.data.buffer);
        this.bufferIndex = 0;
      }
    };
  }

  process(inputs, outputs, parameters) {
    const output = outputs[0];

    if (!this.isRunning) {
      this.port.postMessage({ type: 'getBuffer' });
      this.isRunning = true;
    }

    for (let channel = 0; channel < output.length; channel++) {
      const outputChannel = output[channel];

      for (let i = 0; i < outputChannel.length; i++) {
        if (this.bufferIndex < this.buffer.length) {
          outputChannel[i] = this.buffer[this.bufferIndex];
          this.bufferIndex++;
        } else {
          outputChannel[i] = 0;
          this.port.postMessage({ type: 'getBuffer' });
          this.bufferIndex = 0;
        }
      }
    }

    return true;
  }
}

registerProcessor('krar-processor', KrarProcessor);
