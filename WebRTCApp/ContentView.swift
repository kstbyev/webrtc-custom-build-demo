//
//  ContentView.swift
//  WebRTCApp
//
//  Created by Madi Sharipov on 03.07.2025.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var audioProcessor = WebRTCAudioProcessor()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Text("🎙️ WebRTC Демо Приложение")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Кастомная сборка WebRTC с инжекцией шума")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Status indicator
                HStack {
                    Circle()
                        .fill(audioProcessor.isProcessing ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    Text(audioProcessor.isProcessing ? "Обработка аудио активна" : "Обработка аудио неактивна")
                        .font(.caption)
                }
                
                // Noise level control
                VStack(spacing: 10) {
                    Text("Уровень шума: \(String(format: "%.2f", audioProcessor.noiseLevel))")
                        .font(.headline)
                    
                    Slider(value: $audioProcessor.noiseLevel, in: 0.0...1.0, step: 0.01)
                        .accentColor(.blue)
                }
                .padding(.horizontal)
                
                // Audio processing controls
                VStack(spacing: 10) {
                    Text("Обработка аудио")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            audioProcessor.startAudioProcessing()
                        }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("Запустить")
                            }
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(audioProcessor.isProcessing)
                        
                        Button(action: {
                            audioProcessor.stopAudioProcessing()
                        }) {
                            HStack {
                                Image(systemName: "stop.circle.fill")
                                Text("Остановить")
                            }
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(!audioProcessor.isProcessing)
                    }
                }
                
                // Status
                VStack(spacing: 10) {
                    Text("Статус")
                        .font(.headline)
                    
                    HStack(spacing: 15) {
                        StatusCard(
                            title: "Кастомная сборка",
                            value: "Готова",
                            color: .blue,
                            icon: "checkmark.circle.fill"
                        )
                        
                        StatusCard(
                            title: "Инжекция шума",
                            value: "Включена",
                            color: .orange,
                            icon: "waveform.path.ecg"
                        )
                    }
                }
                
                // Logs
                VStack(alignment: .leading, spacing: 10) {
                    Text("Журнал обработки")
                        .font(.headline)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 5) {
                            ForEach(audioProcessor.logs, id: \.self) { log in
                                Text(log)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(height: 120)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Info
                VStack(spacing: 5) {
                    Text("ℹ️ Настоящая WebRTC интеграция активна")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("WebRTC M110 (218b56e) с патчем инжекции шума")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Проверьте консоль для логов WebRTC обработки")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
        .onAppear {
            requestMicrophonePermission()
        }
    }
    
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    audioProcessor.addLog("✅ Разрешение на микрофон получено")
                } else {
                    audioProcessor.addLog("❌ Разрешение на микрофон отклонено")
                }
            }
        }
    }
}

struct StatusCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    ContentView()
}
