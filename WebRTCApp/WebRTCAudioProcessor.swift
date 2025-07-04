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
    
    // WebRTC интеграция - реальные нативные вызовы
    private var webRTCProcessor: UnsafeMutableRawPointer?
    private let sampleRate: Int32 = 48000
    private let channels: Int32 = 2
    
    private var playerNode: AVAudioPlayerNode?
    private var audioBufferQueue = DispatchQueue(label: "audio.buffer.queue")
    
    init() {
        addLog("🎯 WebRTC Audio Processor инициализирован")
        addLog("📦 Кастомная сборка WebRTC M110 (218b56e)")
        addLog("🔧 Инжекция шума активна в AudioProcessingImpl")
        setupAudioSession()
        initializeWebRTC()
    }
    
    deinit {
        cleanupWebRTC()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true)
            addLog("✅ Audio Session настроен")
            addLog("🎤 AVAudioSession активирован: \(audioSession.isOtherAudioPlaying ? "есть другой звук" : "нет других источников")")
        } catch {
            addLog("❌ Ошибка настройки Audio Session: \(error.localizedDescription)")
        }
    }
    
    func startAudioProcessing() {
        guard !isProcessing else { return }
        addLog("🚀 Запуск WebRTC аудио обработки...")
        guard webRTCProcessor != nil else {
            addLog("❌ WebRTC процессор не инициализирован")
            return
        }
        do {
            audioEngine = AVAudioEngine()
            inputNode = audioEngine?.inputNode
            outputNode = audioEngine?.outputNode
            guard let inputNode = inputNode,
                  let outputNode = outputNode,
                  let audioEngine = audioEngine else {
                addLog("❌ Ошибка инициализации AVAudioEngine")
                return
            }
            audioFormat = inputNode.outputFormat(forBus: 0)
            addLog("🎵 Аудио формат: \(audioFormat?.description ?? "неизвестно")")
            // Отключаем прямой вывод inputNode на outputNode
            audioEngine.disconnectNodeOutput(inputNode)
            // Настраиваем playerNode
            playerNode = AVAudioPlayerNode()
            audioEngine.attach(playerNode!)
            if let format = audioFormat {
                audioEngine.connect(playerNode!, to: outputNode, format: format)
            }
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: audioFormat) { [weak self] buffer, time in
                self?.processAudioBuffer(buffer)
            }
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isProcessing = true
            }
            addLog("✅ WebRTC аудио обработка запущена")
            addLog("🔊 Инжекция шума активна (уровень: \(String(format: "%.3f", noiseLevel)))")
        } catch {
            addLog("❌ Ошибка запуска аудио обработки: \(error.localizedDescription)")
        }
    }
    
    func stopAudioProcessing() {
        guard isProcessing else { return }
        addLog("🛑 Остановка WebRTC аудио обработки...")
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        playerNode?.stop()
        playerNode = nil
        audioEngine = nil
        inputNode = nil
        outputNode = nil
        audioFormat = nil
        DispatchQueue.main.async {
            self.isProcessing = false
        }
        addLog("✅ WebRTC аудио обработка остановлена")
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let webRTCProcessor = webRTCProcessor,
              let audioFormat = audioFormat else { return }
        let frameCount = Int(buffer.frameLength)
        let channelCount = Int(audioFormat.channelCount)
        addLog("🔄 Обработка аудиобуфера: \(frameCount) сэмплов, \(channelCount) каналов")
        // Используем ContiguousArray для гарантии непрерывности памяти
        var inputData: [ContiguousArray<Float>] = Array(repeating: ContiguousArray(repeating: 0.0, count: frameCount), count: channelCount)
        var outputData: [ContiguousArray<Float>] = Array(repeating: ContiguousArray(repeating: 0.0, count: frameCount), count: channelCount)
        if let floatChannelData = buffer.floatChannelData {
            for ch in 0..<channelCount {
                let channelData = floatChannelData[ch]
                for i in 0..<frameCount {
                    inputData[ch][i] = channelData[i]
                }
            }
        }
        let result = processAudioWithWebRTC(
            processor: webRTCProcessor,
            input: inputData,
            output: &outputData,
            frames: Int32(frameCount),
            noiseLevel: noiseLevel
        )
        // Преобразуем обратно в [[Float]] для воспроизведения
        let outputFloatData: [[Float]] = outputData.map { Array($0) }
        if result > 0 {
            addLog("🎛️ WebRTC обработка: шум добавлен в \(frameCount) сэмплов")
            playProcessedAudio(outputFloatData, format: audioFormat)
        }
        addLog("✅ Обработка аудиобуфера завершена")
    }
    
    private func playProcessedAudio(_ audioData: [[Float]], format: AVAudioFormat) {
        addLog("▶️ playProcessedAudio вызван, samples: \(audioData.first?.count ?? 0), channels: \(audioData.count)")
        let flat = audioData.flatMap { $0 }
        let minVal = flat.min() ?? 0
        let maxVal = flat.max() ?? 0
        addLog("🔊 Буфер для воспроизведения: min=\(minVal), max=\(maxVal)")
        guard let playerNode = playerNode else { return }
        let frameCount = AVAudioFrameCount(audioData[0].count)
        let channelCount = audioData.count
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        for ch in 0..<channelCount {
            if let channelData = buffer.floatChannelData?[ch] {
                for i in 0..<Int(frameCount) {
                    channelData[i] = audioData[ch][i]
                }
            }
        }
        audioBufferQueue.async {
            playerNode.scheduleBuffer(buffer, completionHandler: nil)
            if !playerNode.isPlaying {
                playerNode.play()
                self.addLog("▶️ playerNode.play() вызван")
            }
        }
    }
    
    func setNoiseLevel(_ level: Float) {
        noiseLevel = level
        addLog("🎛️ Уровень шума обновлен до: \(String(format: "%.3f", level))")
        addLog("📊 WebRTC AudioProcessingImpl будет использовать новый уровень")
        
        // Обновляем уровень шума в нативном WebRTC процессоре
        if let webRTCProcessor = webRTCProcessor {
            setNoiseLevelNative(processor: webRTCProcessor, level: level)
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
    
    // MARK: - WebRTC Native Integration
    
    private func initializeWebRTC() {
        addLog("🔧 Инициализация нативного WebRTC процессора...")
        
        // Создаем нативный WebRTC процессор
        webRTCProcessor = createAudioProcessor(sampleRate, channels)
        
        if webRTCProcessor != nil {
            addLog("✅ Нативный WebRTC процессор создан успешно")
            addLog("📊 Параметры: \(sampleRate)Hz, \(channels) каналов")
        } else {
            addLog("❌ Ошибка создания нативного WebRTC процессора")
        }
    }
    
    private func cleanupWebRTC() {
        if let processor = webRTCProcessor {
            destroyAudioProcessor(processor)
            webRTCProcessor = nil
            addLog("🧹 WebRTC процессор очищен")
        }
    }
    
    private func processAudioWithWebRTC(
        processor: UnsafeMutableRawPointer,
        input: [ContiguousArray<Float>],
        output: inout [ContiguousArray<Float>],
        frames: Int32,
        noiseLevel: Float
    ) -> Int {
        var inputPointers: [UnsafePointer<Float>?] = input.map { $0.withUnsafeBufferPointer { $0.baseAddress } }
        var outputPointers: [UnsafeMutablePointer<Float>?] = []
        for i in 0..<output.count {
            outputPointers.append(output[i].withUnsafeMutableBufferPointer { $0.baseAddress })
        }
        assert(inputPointers.allSatisfy { $0 != nil }, "inputPointers contains nil")
        assert(outputPointers.allSatisfy { $0 != nil }, "outputPointers contains nil")
        let inputCArray = inputPointers.withUnsafeMutableBufferPointer { $0.baseAddress }
        let outputCArray = outputPointers.withUnsafeMutableBufferPointer { $0.baseAddress }
        return Int(processAudio(
            processor,
            inputCArray,
            outputCArray,
            frames,
            noiseLevel
        ))
    }
    
    private func setNoiseLevelNative(processor: UnsafeMutableRawPointer, level: Float) {
        setNoiseLevelNative(processor: processor, level: level)
    }
}

// MARK: - WebRTC Native Functions (imported from C++)

// Эти функции импортируются из WebRTCWrapper.cpp через bridging header
// Они обеспечивают прямую интеграцию с нативным WebRTC кодом 