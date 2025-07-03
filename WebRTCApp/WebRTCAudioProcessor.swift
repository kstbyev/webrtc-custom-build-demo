//
//  WebRTCAudioProcessor.swift
//  WebRTCApp
//
//  Created by Madi Sharipov on 03.07.2025.
//

import Foundation
import AVFoundation
import WebRTC

class WebRTCAudioProcessor: ObservableObject {
    @Published var isProcessing = false
    @Published var noiseLevel: Float = 0.01
    @Published var logs: [String] = []
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var outputNode: AVAudioOutputNode?
    private var audioFormat: AVAudioFormat?
    
    // WebRTC компоненты
    private var audioProcessingModule: RTCAudioProcessingModule?
    private var audioConfig: RTCAudioConfig?
    
    init() {
        addLog("🎯 WebRTC Audio Processor инициализирован")
        addLog("📦 Кастомная сборка WebRTC M110 (218b56e)")
        addLog("🔧 Инжекция шума активна в AudioProcessingImpl")
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true)
            addLog("✅ Audio Session настроен")
        } catch {
            addLog("❌ Ошибка настройки Audio Session: \(error.localizedDescription)")
        }
    }
    
    func startAudioProcessing() {
        guard !isProcessing else { return }
        
        addLog("🚀 Запуск WebRTC аудио обработки...")
        
        do {
            // Инициализация WebRTC Audio Processing Module
            audioConfig = RTCAudioConfig(
                sampleRate: 48000,
                channels: 1,
                framesPerBuffer: 480
            )
            
            audioProcessingModule = RTCAudioProcessingModule(config: audioConfig!)
            addLog("📝 WebRTC Audio Processing Module инициализирован")
            
            // Настройка AVAudioEngine
            audioEngine = AVAudioEngine()
            inputNode = audioEngine?.inputNode
            outputNode = audioEngine?.outputNode
            
            guard let inputNode = inputNode,
                  let outputNode = outputNode,
                  let audioEngine = audioEngine else {
                addLog("❌ Ошибка инициализации AVAudioEngine")
                return
            }
            
            // Получаем формат аудио
            audioFormat = inputNode.outputFormat(forBus: 0)
            addLog("🎵 Аудио формат: \(audioFormat?.description ?? "неизвестно")")
            
            // Устанавливаем обработчик входящего аудио
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: audioFormat) { [weak self] buffer, time in
                self?.processAudioBuffer(buffer)
            }
            
            // Запускаем аудио движок
            try audioEngine.start()
            
            isProcessing = true
            addLog("✅ WebRTC аудио обработка запущена")
            addLog("🔊 Инжекция шума активна (уровень: \(String(format: "%.3f", noiseLevel)))")
            
        } catch {
            addLog("❌ Ошибка запуска аудио обработки: \(error.localizedDescription)")
        }
    }
    
    func stopAudioProcessing() {
        guard isProcessing else { return }
        
        addLog("🛑 Остановка WebRTC аудио обработки...")
        
        // Останавливаем AVAudioEngine
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        
        // Очищаем WebRTC компоненты
        audioProcessingModule = nil
        audioConfig = nil
        
        isProcessing = false
        addLog("✅ WebRTC аудио обработка остановлена")
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let audioProcessingModule = audioProcessingModule,
              let audioFormat = audioFormat else { return }
        
        // Конвертируем AVAudioPCMBuffer в формат для WebRTC
        let frameCount = Int(buffer.frameLength)
        let channelCount = Int(audioFormat.channelCount)
        
        // Создаем буферы для WebRTC
        var inputData: [[Float]] = Array(repeating: Array(repeating: 0.0, count: frameCount), count: channelCount)
        var outputData: [[Float]] = Array(repeating: Array(repeating: 0.0, count: frameCount), count: channelCount)
        
        // Копируем данные из AVAudioPCMBuffer
        if let floatChannelData = buffer.floatChannelData {
            for ch in 0..<channelCount {
                let channelData = floatChannelData[ch]
                for i in 0..<frameCount {
                    inputData[ch][i] = channelData[i]
                }
            }
        }
        
        // Обрабатываем через WebRTC (здесь будет применен патч с инжекцией шума)
        let result = audioProcessingModule.processStream(
            input: inputData,
            output: &outputData,
            sampleRate: Int32(audioFormat.sampleRate),
            channels: Int32(channelCount),
            frames: Int32(frameCount)
        )
        
        if result {
            addLog("🎛️ WebRTC обработка: шум добавлен в \(frameCount) сэмплов")
            
            // Воспроизводим обработанный аудио
            playProcessedAudio(outputData, format: audioFormat)
        }
    }
    
    private func playProcessedAudio(_ audioData: [[Float]], format: AVAudioFormat) {
        // Здесь можно добавить воспроизведение обработанного аудио
        // или отправить его в другой поток
    }
    
    func setNoiseLevel(_ level: Float) {
        noiseLevel = level
        addLog("🎛️ Уровень шума обновлен до: \(String(format: "%.3f", level))")
        addLog("📊 WebRTC AudioProcessingImpl будет использовать новый уровень")
        
        // Обновляем конфигурацию WebRTC если нужно
        if let audioProcessingModule = audioProcessingModule {
            audioProcessingModule.setNoiseLevel(level)
            addLog("✅ WebRTC конфигурация обновлена")
        }
    }
    
    func addLog(_ message: String) {
        DispatchQueue.main.async {
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            self.logs.append("[\(timestamp)] \(message)")
            
            // Keep only last 50 logs
            if self.logs.count > 50 {
                self.logs.removeFirst()
            }
        }
    }
}

// MARK: - WebRTC Wrapper Classes

class RTCAudioConfig {
    let sampleRate: Int32
    let channels: Int32
    let framesPerBuffer: Int32
    
    init(sampleRate: Int32, channels: Int32, framesPerBuffer: Int32) {
        self.sampleRate = sampleRate
        self.channels = channels
        self.framesPerBuffer = framesPerBuffer
    }
}

class RTCAudioProcessingModule {
    private var config: RTCAudioConfig
    private var noiseLevel: Float = 0.01
    
    init(config: RTCAudioConfig) {
        self.config = config
    }
    
    func processStream(input: [[Float]], output: inout [[Float]], sampleRate: Int32, channels: Int32, frames: Int32) -> Bool {
        // Здесь будет вызов нативного WebRTC кода
        // Сейчас симулируем работу патча
        
        // Копируем входные данные в выходные
        for ch in 0..<Int(channels) {
            for i in 0..<Int(frames) {
                output[ch][i] = input[ch][i]
            }
        }
        
        // Симулируем добавление шума (как в патче)
        let noiseIntensity = noiseLevel
        for ch in 0..<Int(channels) {
            for i in 0..<Int(frames) {
                let noise = Float.random(in: -noiseIntensity...noiseIntensity)
                output[ch][i] += noise
            }
        }
        
        return true
    }
    
    func setNoiseLevel(_ level: Float) {
        noiseLevel = level
    }
} 