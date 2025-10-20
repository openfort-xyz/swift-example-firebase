//
//  AccountRecoveryView.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-04.
//

import SwiftUI

struct AccountRecoveryView: View {
    @State private var password: String = ""
    @State private var loadingPwd: Bool = false
    @State private var loadingAut: Bool = false
    @State private var status: StatusType? = nil
    @FocusState private var focused: Bool

    var handleRecovery: (_ method: RecoveryMethod, _ password: String?) async throws -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Account recovery")
                .font(.title2)
                .bold()
                .padding(.bottom, 16)

            VStack(spacing: 0) {
                // Password input
                TextField("Password to secure your recovery", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .focused($focused)
                    .padding(.bottom, 12)

                Button {
                    Task {
                        loadingPwd = true
                        do {
                            print("[AccountRecovery] Starting password recovery with password: \(password.isEmpty ? "<empty>" : "<provided>")")
                            try await handleRecovery(.password, password)
                            print("[AccountRecovery] Password recovery succeeded!")
                            status = .success("Recovery configured successfully!")
                        } catch let error as MissingRecoveryPasswordError {
                            status = .error("Missing recovery password")
                        } catch let error as WrongRecoveryPasswordError {
                            status = .error("Wrong recovery password")
                        } catch {
                            print("[AccountRecovery] Error details: \(error)")
                            print("[AccountRecovery] Error localized: \(error.localizedDescription)")
                            if let nsError = error as NSError? {
                                print("[AccountRecovery] Error domain: \(nsError.domain)")
                                print("[AccountRecovery] Error code: \(nsError.code)")
                                print("[AccountRecovery] Error userInfo: \(nsError.userInfo)")
                            }
                            status = .error("Error: \(error.localizedDescription)")
                        }
                        loadingPwd = false
                    }
                } label: {
                    if loadingPwd {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Continue with Password Recovery")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(loadingPwd)
                .padding(.bottom, 16)

                // OR separator
                HStack {
                    Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                    Text("Or").foregroundColor(.gray).padding(.horizontal, 8)
                    Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                }
                .padding(.vertical, 16)

                // Automatic recovery
                Button {
                    Task {
                        loadingAut = true
                        do {
                            print("[AccountRecovery] Starting automatic recovery...")
                            try await handleRecovery(.automatic, nil)
                            print("[AccountRecovery] Automatic recovery succeeded!")
                            status = .success("Recovery configured successfully!")
                        } catch let error as MissingRecoveryPasswordError {
                            status = .error("Missing recovery password")
                        } catch let error as WrongRecoveryPasswordError {
                            status = .error("Wrong recovery password")
                        } catch {
                            print("[AccountRecovery] Error details: \(error)")
                            print("[AccountRecovery] Error localized: \(error.localizedDescription)")
                            if let nsError = error as NSError? {
                                print("[AccountRecovery] Error domain: \(nsError.domain)")
                                print("[AccountRecovery] Error code: \(nsError.code)")
                                print("[AccountRecovery] Error userInfo: \(nsError.userInfo)")
                            }
                            status = .error("Error: \(error.localizedDescription)")
                        }
                        loadingAut = false
                    }
                } label: {
                    if loadingAut {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Continue with Automatic Recovery")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(loadingAut)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
        .toast(isPresented: .constant(status != nil), message: status?.description ?? "") {
            status = nil
        }
    }
}

// Helper for error type/status display
enum StatusType {
    case error(String)
    case success(String)

    var description: String {
        switch self {
        case .error(let msg): return msg
        case .success(let msg): return msg
        }
    }
}

enum RecoveryMethod {
    case password
    case automatic
}

// Define your error types, or use your existing ones
struct MissingRecoveryPasswordError: Error {}
struct WrongRecoveryPasswordError: Error {}

// Toast extension (as in your HomeView)
extension View {
    func toast(isPresented: Binding<Bool>, message: String, onDismiss: @escaping () -> Void) -> some View {
        ZStack {
            self
            if isPresented.wrappedValue {
                Text(message)
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .transition(.move(edge: .top))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                isPresented.wrappedValue = false
                                onDismiss()
                            }
                        }
                    }
                    .zIndex(2)
            }
        }
    }
}
