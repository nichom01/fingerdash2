import SwiftUI

public struct ContentView: View {
    public var body: some View {
        OverheadFeetView()
    }
    
    public init() {}
}

public struct OverheadFeetView: View {
    @State private var leftFootOffset: CGFloat = 0
    @State private var rightFootOffset: CGFloat = 0
    @State private var draggingFoot: FootSide? = nil
    @State private var dragStartOffset: CGFloat = 0
    @State private var totalDistanceTraveled: Double = 0
    @State private var currentDragDistance: CGFloat = 0
    @State private var lastFootDragged: FootSide? = nil
    @State private var lastStrideTime: Date? = nil
    @State private var currentSpeed: Double = 0.0
    
    // Each stride (one foot drag) adds 0.6 meters
    private let strideLength: Double = 0.6
    
    public init() {}
    
    private var distanceInMeters: Double {
        totalDistanceTraveled
    }
    
    private var speedInMetersPerSecond: Double {
        currentSpeed
    }
    
    // Check if a foot can be dragged (must alternate)
    private func canDragFoot(_ foot: FootSide) -> Bool {
        // Can drag if no foot is currently being dragged
        guard draggingFoot == nil else { return false }
        // If no foot has been dragged yet, either foot can start
        guard let lastFoot = lastFootDragged else { return true }
        // Can only drag the opposite foot
        return foot != lastFoot
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                // Distance and speed counters in top right
                VStack {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(String(format: "%.1f m", distanceInMeters))
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                            Text(String(format: "%.2f m/s", speedInMetersPerSecond))
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 20)
                    }
                    Spacer()
                }
                .task {
                    // Timer to decrease speed when idle and increase distance based on momentum
                    let tickInterval: Double = 0.1 // seconds
                    while true {
                        try? await Task.sleep(nanoseconds: UInt64(tickInterval * 1_000_000_000))
                        
                        if currentSpeed > 0 {
                            // Increase distance based on current speed (distance = speed * time)
                            totalDistanceTraveled += currentSpeed * tickInterval
                            
                            // Decrease speed by 0.5 m/s per second (0.05 per 0.1s tick)
                            currentSpeed = max(0, currentSpeed - 0.05)
                        }
                    }
                }
                
                VStack(spacing: 20) {
                    // Spacer to push feet to 2/3 down the screen
                    Spacer()
                        .frame(height: geometry.size.height * 2/3)
                    
                    HStack(spacing: 40) {
                        FootView(
                            side: .left,
                            offset: leftFootOffset,
                            isDragging: draggingFoot == .left,
                            canDrag: canDragFoot(.left),
                            onDrag: { translation in
                                // Only allow downward movement (positive Y)
                                // Add to the starting offset
                                let newOffset = dragStartOffset + max(0, translation)
                                leftFootOffset = newOffset
                                // Update current drag distance
                                currentDragDistance = max(0, translation)
                            },
                            onDragEnd: {
                                // Calculate speed based on time between strides
                                let now = Date()
                                if let lastTime = lastStrideTime {
                                    let timeInterval = now.timeIntervalSince(lastTime)
                                    if timeInterval > 0 {
                                        // Speed = stride length / time between strides
                                        currentSpeed = strideLength / timeInterval
                                    }
                                } else {
                                    // First stride, no speed yet
                                    currentSpeed = 0.0
                                }
                                lastStrideTime = now
                                
                                // Add one stride (0.6m) to total distance
                                totalDistanceTraveled += strideLength
                                // Record that left foot was just dragged
                                lastFootDragged = .left
                                // Return foot to original position
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    leftFootOffset = 0
                                }
                                currentDragDistance = 0
                                draggingFoot = nil
                            },
                            onDragStart: {
                                // Only allow dragging if this foot can be dragged (alternating)
                                if canDragFoot(.left) {
                                    draggingFoot = .left
                                    dragStartOffset = leftFootOffset
                                    currentDragDistance = 0
                                }
                            }
                        )
                        
                        FootView(
                            side: .right,
                            offset: rightFootOffset,
                            isDragging: draggingFoot == .right,
                            canDrag: canDragFoot(.right),
                            onDrag: { translation in
                                // Only allow downward movement (positive Y)
                                // Add to the starting offset
                                let newOffset = dragStartOffset + max(0, translation)
                                rightFootOffset = newOffset
                                // Update current drag distance
                                currentDragDistance = max(0, translation)
                            },
                            onDragEnd: {
                                // Calculate speed based on time between strides
                                let now = Date()
                                if let lastTime = lastStrideTime {
                                    let timeInterval = now.timeIntervalSince(lastTime)
                                    if timeInterval > 0 {
                                        // Speed = stride length / time between strides
                                        currentSpeed = strideLength / timeInterval
                                    }
                                } else {
                                    // First stride, no speed yet
                                    currentSpeed = 0.0
                                }
                                lastStrideTime = now
                                
                                // Add one stride (0.6m) to total distance
                                totalDistanceTraveled += strideLength
                                // Record that right foot was just dragged
                                lastFootDragged = .right
                                // Return foot to original position
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    rightFootOffset = 0
                                }
                                currentDragDistance = 0
                                draggingFoot = nil
                            },
                            onDragStart: {
                                // Only allow dragging if this foot can be dragged (alternating)
                                if canDragFoot(.right) {
                                    draggingFoot = .right
                                    dragStartOffset = rightFootOffset
                                    currentDragDistance = 0
                                }
                            }
                        )
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
    let offset: CGFloat
    let isDragging: Bool
    let canDrag: Bool
    let onDrag: (CGFloat) -> Void
    let onDragEnd: () -> Void
    let onDragStart: () -> Void
    
    // Determine foot color based on state
    private var footColor: Color {
        if isDragging {
            return .blue
        } else if canDrag {
            return .green
        } else {
            return .blue
        }
    }
    
    private var footOpacity: Double {
        if isDragging {
            return 0.5
        } else if canDrag {
            return 0.4
        } else {
            return 0.3
        }
    }
    
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
            .fill(footColor.opacity(footOpacity))
            .stroke(footColor, lineWidth: isDragging ? 4 : 3)
            .frame(width: 40, height: 65)
            .scaleEffect(x: side == .left ? 1 : -1, y: 1, anchor: .center)
            
            // Toes
            VStack(spacing: 2) {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(footColor.opacity(0.5))
                        .frame(width: 4, height: 4)
                }
            }
            .offset(x: 0, y: -25)
            .scaleEffect(x: side == .left ? 1 : -1, y: 1, anchor: .center)
        }
        .offset(y: offset)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // Start dragging if this foot can be dragged and isn't already being dragged
                    if canDrag && !isDragging {
                        onDragStart()
                    }
                    
                    // Only process if this foot is the one being dragged
                    if isDragging {
                        // Constrain to only downward movement (positive Y translation)
                        // Only allow movement if dragging downward
                        let downwardTranslation = max(0, value.translation.height)
                        onDrag(downwardTranslation)
                    }
                }
                .onEnded { _ in
                    if isDragging {
                        onDragEnd()
                    }
                }
        )
    }
}
