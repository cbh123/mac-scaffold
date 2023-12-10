//
//  ContentView.swift
//  MacScaffold
//
//  Created by Charlie Holtz on 12/10/23.
//

import SwiftUI
import CryptoKit
import Replicate


// https://replicate.com/stability-ai/stable-diffusion
enum StableDiffusion: Predictable {
  static var modelID = "fofr/latent-consistency-model"
  static let versionID = "a83d4056c205f4f62ae2d19f73b04881db59ce8b81154d314dd34ab7babaa0f1"

  struct Input: Codable {
      let prompt: String
  }

  typealias Output = [URL]
}

struct ContentView: View {
    @State private var prompt: String = ""
    @State private var gravatarURL: URL?
    @State private var prediction: StableDiffusion.Prediction? = nil
    @State private var timer: Timer? = nil
    
    @AppStorage("replicateToken") var replicateToken: String = ""

    private var client: Replicate.Client {
        Replicate.Client(token: replicateToken)
    }
    
    // Debounce properties
    private let debounceInterval: TimeInterval = 1.0  // Adjust as needed


    
    func generate() async throws {
      prediction = try await StableDiffusion.predict(with: client,
                                                     input: .init(prompt: prompt))
      try await prediction?.wait(with: client)
    }
    
    func debounceGenerate() {
        timer?.invalidate()  // Invalidate the existing timer
        timer = nil

        // Only proceed if the text is not empty
        guard !prompt.isEmpty else {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { _ in
            Task {
                try await self.generate()
            }
        }
    }


    func cancel() async throws {
      try await prediction?.cancel(with: client)
    }

    var body: some View {
        VStack {
            TextField("Enter text", text: $prompt)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onChange(of: prompt) { newValue in
                    Task {
                        debounceGenerate()
                    }
                }
            if let prediction {
              ZStack {
                Color.clear
                  .aspectRatio(1.0, contentMode: .fit)

                switch prediction.status {
                case .starting, .processing:
                  VStack{
                    ProgressView("Generating...")
                      .padding(32)

                    Button("Cancel") {
                      Task { try await cancel() }
                    }
                  }
                case .succeeded:
                  if let url = prediction.output?.first {
                    VStack {
                      AsyncImage(url: url, scale: 2.0, content: { phase in
                        phase.image?
                          .resizable()
                          .aspectRatio(contentMode: .fit)
                          .cornerRadius(32)
                      })

                      ShareLink("Export", item: url)
                        .padding(32)
                    }
                  }
                case .failed:
                  Text(prediction.error?.localizedDescription ?? "Unknown error")
                    .foregroundColor(.red)
                case .canceled:
                  Text("The prediction was canceled")
                    .foregroundColor(.secondary)
                }
              }
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
              .padding()
              .listRowBackground(Color.clear)
              .listRowInsets(.init())
            }
        }
        }

        

}

#Preview {
    ContentView()
}
