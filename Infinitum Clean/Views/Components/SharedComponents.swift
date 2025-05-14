import SwiftUI

struct Theme {
    static let background = Color(UIColor.systemBackground)
    static let card = Color(UIColor.secondarySystemBackground)
    static let primary = Color.accentColor // systemBlue
    static let secondary = Color(UIColor.systemIndigo)
    static let destructive = Color(UIColor.systemRed)
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let border = Color(UIColor.separator)
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .symbolEffect(.bounce, options: .repeating)
                Text(title)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Theme.border.opacity(0.5), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

struct HealthMetricRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 30)
                .foregroundColor(Theme.primary)
                .symbolEffect(.pulse)
            Text(title)
                .foregroundColor(Theme.textPrimary)
            Spacer()
            Text(value)
                .foregroundColor(Theme.textSecondary)
                .fontWeight(.medium)
        }
    }
}

struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .background(Theme.card)
                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Theme.border.opacity(0.2), lineWidth: 1)
            )
    }
}

struct AnimatedGradient: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [Theme.primary, Theme.secondary, Theme.primary],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .opacity(0.18)
        .onAppear {
            withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

struct ModernProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.card)
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(color)
                    .frame(width: geometry.size.width * progress, height: 8)
                    .animation(.spring(), value: progress)
            }
        }
        .frame(height: 8)
    }
}

struct ModernToggle: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Theme.primary)
                    .symbolEffect(.bounce, options: .repeating)
                Text(title)
                    .foregroundColor(Theme.textPrimary)
            }
        }
        .tint(Theme.primary)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
    }
}

struct ModernNavigationBar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

extension View {
    func modernNavigationBar() -> some View {
        modifier(ModernNavigationBar())
    }
} 