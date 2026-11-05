//
//  IdentityGateView.swift
//  MinisApp — modified build
//
//  Startup passcode screen. The main UI stays unmounted until this
//  resolves, so nothing touches ChatStore.shared before the storage
//  root is selected.
//

import SwiftUI

struct IdentityGateView: View {
    @ObservedObject private var gate = IdentityGate.shared
    @State private var code = ""
    @State private var shake = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "lock.fill")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("Enter Passcode")
                .font(.title3.bold())
            SecureField("", text: $code)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .frame(maxWidth: 220)
                .submitLabel(.go)
                .onSubmit(submit)
            Button(action: submit) {
                Label("Unlock", systemImage: "arrow.right.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
            .disabled(code.isEmpty)
            if gate.failedAttempt > 0 {
                Text("Wrong passcode")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            Spacer()
            Spacer()
        }
        .padding()
        .offset(x: shake ? -10 : 0)
        .animation(.easeInOut(duration: 0.06), value: shake)
    }

    private func submit() {
        guard !code.isEmpty else { return }
        if gate.submit(code) {
            // Storage root must be pinned before any store singleton exists.
            ChatPaths.activate(gate.resolved!)
            code = ""
        } else {
            code = ""
            shake = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { shake = false }
        }
    }
}
