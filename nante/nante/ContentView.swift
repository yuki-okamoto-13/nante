//
//  ContentView.swift
//  nante
//
//  Created by okamoto yuki on 2024/07/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = ContentViewModel()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    Spacer().frame(height: 40)

                    ZStack(alignment: .bottomTrailing) {
                        VStack {
                            HStack {
                                Spacer()
                                Picker("Language", selection: $viewModel.selectedSpeechRecognitionLanguage) {
                                    ForEach(viewModel.speechRecognitionLanguages, id: \.self) { language in
                                        Text(language)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            TextEditor(text: $viewModel.transcript)
                                .frame(height: geometry.size.height / 3)
                                .padding(EdgeInsets.init(top: 8, leading: 8, bottom: 8, trailing: 8))
                                .background(Color.gray.opacity(0.5))
                                .cornerRadius(8)
                                .disabled(true) // 読み取り専用にする
                        }
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: {
                                    if viewModel.isRecording {
                                        viewModel.stopTranscribing()
                                    } else {
                                        viewModel.startTranscribing()
                                    }
                                }) {
                                    Image(systemName: viewModel.canRecord ? (viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill") : "mic.slash.circle.fill")
                                        .font(.system(size: 40))
                                }
                                .padding()
                            }
                        }
                    }

                    Spacer().frame(height: 40)

                    ZStack(alignment: .bottomTrailing) {
                        VStack {
                            HStack {
                                Spacer()
                                Picker("Language", selection: $viewModel.selectedTranslationLanguage) {
                                    ForEach(viewModel.translationLanguages, id: \.self) { language in
                                        Text(language)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            TextEditor(text: $viewModel.translatedText)
                                .frame(height: geometry.size.height / 3)
                                .padding(EdgeInsets.init(top: 8, leading: 8, bottom: 8, trailing: 8))
                                .background(Color.gray.opacity(0.5))
                                .cornerRadius(8)
                                .disabled(true) // 読み取り専用にする
                        }
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: {
                                    if viewModel.isPlaying {
                                        viewModel.stopSpeak()
                                    } else {
                                        viewModel.playSpeak()
                                    }
                                }) {
                                    Image(systemName: viewModel.canPlay ? (viewModel.isPlaying ? "stop.circle.fill" : "play.circle.fill") : "play.slash.fill")
                                        .font(.system(size: 40))
                                }
                                .padding()
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal)

                // 読み込み中のオーバーレイ
                if viewModel.isLoading {
                    Color.black.opacity(0.6)
                        .edgesIgnoringSafeArea(.all)

                    VStack {
                        ProgressView("Loading...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(Color.white)
                            .foregroundColor(.white)
                    }
                }
            }.onAppear {
                viewModel.requestAuthorization()
            }
        }
    }
}

#Preview {
    ContentView()
}
