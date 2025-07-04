#ifndef WebRTCApp_Bridging_Header_h
#define WebRTCApp_Bridging_Header_h

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Импортируем C wrapper функции
void* createAudioProcessor(int sampleRate, int channels);
int processAudio(void* processor, const float** input, float** output, int frames, float noiseLevel);
void destroyAudioProcessor(void* processor);
void setNoiseLevel(void* processor, float noiseLevel);
float getNoiseLevel(void* processor);

#ifdef __cplusplus
}
#endif

#endif /* WebRTCApp_Bridging_Header_h */ 