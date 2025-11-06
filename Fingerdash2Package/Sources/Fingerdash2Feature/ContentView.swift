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
    @State private var isJumping: Bool = false
    @State private var timerStartTime: Date? = nil
    @State private var elapsedTime: TimeInterval = 0.0
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var topTimes: [TimeInterval] = [30.00, 30.00, 30.00] // Gold, Silver, Bronze
    @State private var showFireworks: Bool = false
    @State private var animateTimeToRecord: Bool = false
    @State private var newRecordIndex: Int? = nil
    @State private var animatingTime: TimeInterval? = nil
    
    // Target distance and stride length
    private let targetDistance: Double = 10.0 // meters
    private let strideLength: Double = 0.6
    
    // UserDefaults key for persisting records
    private let topTimesKey = "TopTimes"
    
    public init() {}
    
    private var distanceInMeters: Double {
        totalDistanceTraveled
    }
    
    private var speedInMetersPerSecond: Double {
        currentSpeed
    }
    
    private var remainingDistance: Double {
        max(0, targetDistance - totalDistanceTraveled)
    }
    
    private var isTargetReached: Bool {
        remainingDistance <= 0
    }
    
    private var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let milliseconds = Int((elapsedTime.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    private func formatTimeSeconds(_ time: TimeInterval) -> String {
        return String(format: "%.2f", time)
    }
    
    // Load top times from UserDefaults
    private func loadTopTimes() {
        if let savedTimes = UserDefaults.standard.array(forKey: topTimesKey) as? [Double],
           savedTimes.count == 3 {
            topTimes = savedTimes.map { TimeInterval($0) }
        } else {
            // Use default values if no saved records exist
            topTimes = [30.00, 30.00, 30.00]
        }
    }
    
    // Save top times to UserDefaults
    private func saveTopTimes() {
        let timesToSave = topTimes.map { Double($0) }
        UserDefaults.standard.set(timesToSave, forKey: topTimesKey)
    }
    
    private func updateTopTimesIfNeeded() {
        guard isTargetReached else { return }
        let newTime = elapsedTime
        
        // Check if new time is better than any of the top 3
        if newTime < topTimes[2] {
            // Find which position this time will take
            var updatedTimes = topTimes + [newTime]
            updatedTimes.sort()
            let newIndex = updatedTimes.firstIndex(of: newTime) ?? 2
            
            // Store the animating time and position
            animatingTime = newTime
            newRecordIndex = newIndex
            
            // Start animation
            withAnimation(.easeInOut(duration: 2.0)) {
                animateTimeToRecord = true
            }
            
            // Show fireworks
            showFireworks = true
            
            // Update top times after animation starts
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                topTimes = Array(updatedTimes.prefix(3))
                saveTopTimes() // Persist the updated records
                animateTimeToRecord = false
                animatingTime = nil
                newRecordIndex = nil
                
                // Hide fireworks after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showFireworks = false
                }
            }
        }
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
    
    // Start the timer
    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task {
            let updateInterval: Double = 0.01 // Update every 10ms for smooth display
            while !isTargetReached {
                try? await Task.sleep(nanoseconds: UInt64(updateInterval * 1_000_000_000))
                
                if let startTime = timerStartTime, !isTargetReached {
                    elapsedTime = Date().timeIntervalSince(startTime)
                } else {
                    break
                }
            }
        }
    }
    
    // Reset the game state
    private func restartGame() {
        // Cancel any running timers
        timerTask?.cancel()
        timerTask = nil
        
        // Reset all state variables
        leftFootOffset = 0
        rightFootOffset = 0
        draggingFoot = nil
        dragStartOffset = 0
        totalDistanceTraveled = 0
        currentDragDistance = 0
        lastFootDragged = nil
        lastStrideTime = nil
        currentSpeed = 0.0
        isJumping = false
        timerStartTime = nil
        elapsedTime = 0.0
        showFireworks = false
        animateTimeToRecord = false
        newRecordIndex = nil
        animatingTime = nil
    }
    
    public var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top half - Scoreboard style layout
                ZStack {
                    // Black background
                    Color.black
                        .ignoresSafeArea()
                    
                    // Fireworks animation
                    if showFireworks {
                        FireworksView()
                            .ignoresSafeArea()
                    }
                    
                    ZStack {
                        // Records in top right corner
                        VStack {
                            HStack {
                                Spacer()
                                VStack(alignment: .trailing, spacing: 8) {
                                    Text("Records")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.bottom, 4)
                                    
                                    // Gold
                                    HStack(spacing: 6) {
                                        Text("🥇")
                                            .font(.system(size: 16))
                                        Text(formatTimeSeconds(topTimes[0]))
                                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0)) // Gold
                                    }
                                    
                                    // Silver
                                    HStack(spacing: 6) {
                                        Text("🥈")
                                            .font(.system(size: 16))
                                        Text(formatTimeSeconds(topTimes[1]))
                                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                            .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75)) // Silver
                                    }
                                    
                                    // Bronze
                                    HStack(spacing: 6) {
                                        Text("🥉")
                                            .font(.system(size: 16))
                                        Text(formatTimeSeconds(topTimes[2]))
                                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                            .foregroundColor(Color(red: 0.8, green: 0.5, blue: 0.2)) // Bronze
                                    }
                                }
                                .padding(.trailing, 20)
                                .padding(.top, 20)
                            }
                            Spacer()
                        }
                        
                        // Centered content: "To go" and Timer
                        VStack(spacing: 20) {
                            Spacer()
                            
                            // "To go" (centered)
                            Text(String(format: "To go: %.1fm", remainingDistance))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0)) // Yellow/Gold
                            
                            // Timer (centered)
                            ZStack {
                                if let animatingTime = animatingTime, animateTimeToRecord {
                                    // Animated time moving to record position
                                    Text(formatTimeSeconds(animatingTime))
                                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                        .offset(
                                            x: animateTimeToRecord ? geometry.size.width * 0.35 : 0,
                                            y: animateTimeToRecord ? -geometry.size.height * 0.2 : 0
                                        )
                                        .opacity(animateTimeToRecord ? 0.0 : 1.0)
                                        .scaleEffect(animateTimeToRecord ? 0.5 : 1.0)
                                }
                                
                                Text(formattedTime)
                                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .opacity(animateTimeToRecord ? 0.0 : 1.0)
                            }
                            
                            Spacer()
                            
                            // Restart button (only shown when race is complete)
                            if isTargetReached {
                                Button(action: {
                                    restartGame()
                                }) {
                                    Text("Restart")
                                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 32)
                                        .padding(.vertical, 14)
                                        .background(Color.green)
                                        .cornerRadius(12)
                                }
                                .padding(.top, 16)
                            }
                            
                            Spacer()
                        }
                    }
                }
                .frame(height: geometry.size.height / 2)
                
                // Separator line
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // Bottom half - Feet, Stats, and Button
                ZStack {
                    // Track background
                    TrackBackgroundView()
                        .ignoresSafeArea()
                    
                    // Stats in top right of bottom half
                    VStack {
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(String(format: "%.1f m", distanceInMeters))
                                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                Text(String(format: "%.2f m/s", speedInMetersPerSecond))
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.trailing, 20)
                            .padding(.top, 20)
                        }
                        Spacer()
                    }
                    
                    // Jump/Throw button in bottom left
                    VStack {
                        Spacer()
                        HStack {
                            Button(action: {
                                // Jump action
                                guard !isJumping else { return }
                                
                                // Jump up phase - scale up and turn orange
                                withAnimation(.easeOut(duration: 0.3)) {
                                    isJumping = true
                                }
                                
                                // Land phase - scale back down and return to normal color
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    withAnimation(.easeIn(duration: 0.3)) {
                                        isJumping = false
                                    }
                                }
                            }) {
                                Text("Jump")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                            .disabled(isJumping)
                            .padding(.leading, 20)
                            .padding(.bottom, 20)
                            Spacer()
                        }
                    }
                    
                    // Feet centered in bottom half
                    VStack(spacing: 20) {
                        Spacer()
                        
                        HStack(spacing: 40) {
                        FootView(
                            side: .left,
                            offset: leftFootOffset,
                            isDragging: draggingFoot == .left,
                            canDrag: canDragFoot(.left),
                            isJumping: isJumping,
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
                                
                                // Add one stride (0.6m) to total distance (only if target not reached)
                                if !isTargetReached {
                                    totalDistanceTraveled += strideLength
                                }
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
                                    
                                    // Start timer on first movement
                                    if timerStartTime == nil {
                                        timerStartTime = Date()
                                        startTimer()
                                    }
                                }
                            }
                        )
                        
                        FootView(
                            side: .right,
                            offset: rightFootOffset,
                            isDragging: draggingFoot == .right,
                            canDrag: canDragFoot(.right),
                            isJumping: isJumping,
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
                                
                                // Add one stride (0.6m) to total distance (only if target not reached)
                                if !isTargetReached {
                                    totalDistanceTraveled += strideLength
                                }
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
                                    
                                    // Start timer on first movement
                                    if timerStartTime == nil {
                                        timerStartTime = Date()
                                        startTimer()
                                    }
                                }
                            }
                        )
                        }
                        .padding()
                        
                        Spacer()
                    }
                }
                .frame(height: geometry.size.height / 2)
            }
            .task {
                // Timer to decrease speed when idle and increase distance based on momentum
                let tickInterval: Double = 0.1 // seconds
                while true {
                    try? await Task.sleep(nanoseconds: UInt64(tickInterval * 1_000_000_000))
                    
                    // Stop timer if target is reached
                    if isTargetReached && timerTask != nil {
                        timerTask?.cancel()
                        timerTask = nil
                    }
                    
                    if currentSpeed > 0 && !isTargetReached {
                        // Increase distance based on current speed (distance = speed * time)
                        totalDistanceTraveled += currentSpeed * tickInterval
                        
                        // Decrease speed by 0.5 m/s per second (0.05 per 0.1s tick)
                        currentSpeed = max(0, currentSpeed - 0.05)
                    }
                }
            }
            .onAppear {
                loadTopTimes()
            }
            .onChange(of: isTargetReached) { reached in
                if reached {
                    timerTask?.cancel()
                    timerTask = nil
                    updateTopTimesIfNeeded()
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
    let isJumping: Bool
    let onDrag: (CGFloat) -> Void
    let onDragEnd: () -> Void
    let onDragStart: () -> Void
    
    // Determine foot color based on state
    private var footColor: Color {
        if isJumping {
            return .orange
        } else if isDragging {
            return .blue
        } else if canDrag {
            return .green
        } else {
            return .blue
        }
    }
    
    // Scale factor for jump animation
    private var jumpScale: CGFloat {
        isJumping ? 1.3 : 1.0
    }
    
    // Shadow radius for jump animation
    private var shadowRadius: CGFloat {
        isJumping ? 8 : 0
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
        .scaleEffect(jumpScale)
        .shadow(color: isJumping ? Color.black.opacity(0.3) : Color.clear, radius: shadowRadius, x: 0, y: isJumping ? -4 : 0)
        .offset(y: offset)
        .animation(.easeInOut(duration: 0.3), value: isJumping)
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

struct TrackBackgroundView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Reddish-brown track background
                Color(red: 0.6, green: 0.3, blue: 0.2)
                    .ignoresSafeArea()
                
                // Left white line at 1/3 width - full height
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 8, height: geometry.size.height)
                    .position(x: geometry.size.width / 3, y: geometry.size.height / 2)
                
                // Right white line at 2/3 width - full height
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 8, height: geometry.size.height)
                    .position(x: geometry.size.width * 2/3, y: geometry.size.height / 2)
            }
        }
    }
}

struct FireworksView: View {
    @State private var particles: [FireworkParticle] = []
    @State private var animationProgress: Double = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(
                            x: particle.startPosition.x + (particle.endPosition.x - particle.startPosition.x) * particle.progress,
                            y: particle.startPosition.y + (particle.endPosition.y - particle.startPosition.y) * particle.progress
                        )
                        .opacity(particle.opacity * (1.0 - particle.progress))
                }
            }
            .onAppear {
                createFireworks(in: geometry.size)
            }
            .task {
                // Animate particles
                let duration: Double = 2.0
                let steps = 120 // 60fps for 2 seconds
                for step in 0...steps {
                    try? await Task.sleep(nanoseconds: UInt64((duration / Double(steps)) * 1_000_000_000))
                    let progress = Double(step) / Double(steps)
                    
                    for i in 0..<particles.count {
                        let particle = particles[i]
                        let elapsed = max(0, progress - particle.delay)
                        let particleProgress = min(1.0, elapsed / 1.5)
                        particles[i].progress = particleProgress
                    }
                }
            }
        }
    }
    
    private func createFireworks(in size: CGSize) {
        var newParticles: [FireworkParticle] = []
        
        // Create multiple firework bursts
        let burstCount = 5
        for i in 0..<burstCount {
            let delay = Double(i) * 0.3
            let centerX = size.width * (0.3 + Double.random(in: 0...0.4))
            let centerY = size.height * (0.3 + Double.random(in: 0...0.4))
            
            // Create particles for each burst
            for j in 0..<30 {
                let angle = Double(j) * (2 * .pi / 30)
                let distance = Double.random(in: 50...150)
                let color = [Color.red, Color.orange, Color.yellow, Color.green, Color.blue, Color.purple].randomElement() ?? Color.red
                
                let finalX = centerX + cos(angle) * distance
                let finalY = centerY + sin(angle) * distance
                
                let particle = FireworkParticle(
                    id: UUID(),
                    startPosition: CGPoint(x: centerX, y: centerY),
                    endPosition: CGPoint(x: finalX, y: finalY),
                    color: color,
                    size: CGFloat.random(in: 4...8),
                    delay: delay,
                    opacity: 1.0,
                    progress: 0.0
                )
                newParticles.append(particle)
            }
        }
        
        particles = newParticles
    }
}

struct FireworkParticle: Identifiable {
    let id: UUID
    let startPosition: CGPoint
    let endPosition: CGPoint
    let color: Color
    let size: CGFloat
    let delay: Double
    let opacity: Double
    var progress: Double
}
