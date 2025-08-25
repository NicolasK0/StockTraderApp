//
//  ToastView.swift
//  StockTrader
//
//  Created by Nicolas Kousoulas on 8/21/25.
//

import SwiftUI

struct ToastView: View {
    let message: String
    let icon: String
    let backgroundColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.headline)
            
            Text(message)
                .foregroundColor(.white)
                .font(.headline)
                .fontWeight(.medium)
            
            Spacer(minLength: 0)
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Toast Manager
class ToastManager: ObservableObject {
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastIcon = ""
    @Published var toastColor = Color.green
    
    func showSuccess(message: String, icon: String = "checkmark.circle.fill") {
        toastMessage = message
        toastIcon = icon
        toastColor = .green
        showToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showToast = false
        }
    }
    
    func showError(message: String, icon: String = "exclamationmark.circle.fill") {
        toastMessage = message
        toastIcon = icon
        toastColor = .red
        showToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showToast = false
        }
    }
}

// MARK: - Toast View Modifier
struct ToastModifier: ViewModifier {
    @ObservedObject var toastManager: ToastManager
    
    func body(content: Content) -> some View {
        content
            .overlay(
                VStack {
                    if toastManager.showToast {
                        ToastView(
                            message: toastManager.toastMessage,
                            icon: toastManager.toastIcon,
                            backgroundColor: toastManager.toastColor
                        )
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(), value: toastManager.showToast)
                    }
                    
                    Spacer()
                }
                .allowsHitTesting(false)
            )
    }
}

extension View {
    func toast(_ toastManager: ToastManager) -> some View {
        self.modifier(ToastModifier(toastManager: toastManager))
    }
}
