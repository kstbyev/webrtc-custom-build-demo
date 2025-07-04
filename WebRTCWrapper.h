#ifndef WEBRTC_WRAPPER_H
#define WEBRTC_WRAPPER_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Создает экземпляр WebRTC AudioProcessingImpl
void* createAudioProcessor(int sampleRate, int channels);

// Обрабатывает аудио поток с добавлением шума
int processAudio(void* processor, const float** input, float** output, int frames, float noiseLevel);

// Освобождает ресурсы процессора
void destroyAudioProcessor(void* processor);

// Устанавливает уровень шума для процессора
void setNoiseLevel(void* processor, float noiseLevel);

// Получает текущий уровень шума
float getNoiseLevel(void* processor);

#ifdef __cplusplus
}
#endif

#endif // WEBRTC_WRAPPER_H 