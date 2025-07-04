#include "WebRTCWrapper.h"
#include <cstdlib>
#include <ctime>
#include <iostream>

struct AudioProcessorState {
    float noise_level;
    int sample_rate;
    int num_channels;
};

extern "C" {

void* createAudioProcessor(int sampleRate, int channels) {
    AudioProcessorState* state = new AudioProcessorState();
    state->noise_level = 0.0f;
    state->sample_rate = sampleRate;
    state->num_channels = channels;
    std::srand(static_cast<unsigned int>(std::time(nullptr)));
    return static_cast<void*>(state);
}

int processAudio(void* processor, const float** input, float** output, int frames, float noiseLevel) {
    std::cout << "[C++] processAudio called: frames=" << frames << ", noiseLevel=" << noiseLevel << std::endl;
    if (!processor) return 0;
    AudioProcessorState* state = static_cast<AudioProcessorState*>(processor);
    state->noise_level = noiseLevel;
    for (int ch = 0; ch < state->num_channels; ++ch) {
        if (!input[ch] || !output[ch]) continue;
        for (int i = 0; i < frames; ++i) {
            float noise = ((std::rand() / (float)RAND_MAX) * 2.0f - 1.0f) * noiseLevel;
            output[ch][i] = noise;
        }
    }
    return 1;
}

void destroyAudioProcessor(void* processor) {
    if (processor) {
        delete static_cast<AudioProcessorState*>(processor);
    }
}

void setNoiseLevel(void* processor, float noiseLevel) {
    if (processor) {
        static_cast<AudioProcessorState*>(processor)->noise_level = noiseLevel;
    }
}

float getNoiseLevel(void* processor) {
    if (processor) {
        return static_cast<AudioProcessorState*>(processor)->noise_level;
    }
    return 0.0f;
}

} // extern "C" 