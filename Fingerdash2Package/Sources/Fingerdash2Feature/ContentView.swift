import SwiftUI

public struct ContentView: View {
    public var body: some View {
        OverheadFeetView()
    }
    
    public init() {}
}

public struct OverheadFeetView: View {
    public init() {}
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Overhead View of 2 Feet")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    // Spacer to push feet to 2/3 down the screen
                    Spacer()
                        .frame(height: geometry.size.height * 2/3)
                    
                    HStack(spacing: 40) {
                        FootView(side: .left)
                        FootView(side: .right)
                    }
                    .padding()
                    
                    Spacer()
                }
            }
        }
    }
}

enum FootSide {
    case left, right
}

struct FootView: View {
    let side: FootSide
    
    var body: some View {
        ZStack {
            // Foot outline
            Path { path in
                // Toes area (wider at front)
                path.move(to: CGPoint(x: 0, y: 20))
                path.addLine(to: CGPoint(x: 10, y: 0))
                path.addLine(to: CGPoint(x: 30, y: 0))
                path.addLine(to: CGPoint(x: 40, y: 20))
                
                // Arch (narrower in middle)
                path.addLine(to: CGPoint(x: 35, y: 50))
                path.addLine(to: CGPoint(x: 30, y: 60))
                
                // Heel (wider at back)
                path.addLine(to: CGPoint(x: 20, y: 65))
                path.addLine(to: CGPoint(x: 10, y: 60))
                path.addLine(to: CGPoint(x: 5, y: 50))
                path.closeSubpath()
            }
            .fill(Color.blue.opacity(0.3))
            .stroke(Color.blue, lineWidth: 3)
            .frame(width: 40, height: 65)
            .scaleEffect(x: side == .left ? 1 : -1, y: 1, anchor: .center)
            
            // Toes
            VStack(spacing: 2) {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(Color.blue.opacity(0.5))
                        .frame(width: 4, height: 4)
                }
            }
            .offset(x: 0, y: -25)
            .scaleEffect(x: side == .left ? 1 : -1, y: 1, anchor: .center)
        }
    }
}
