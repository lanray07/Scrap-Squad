import Foundation

public struct RobotFootstep: Sendable, Equatable {
    public let position: Vector
    public let direction: Vector
    public let side: Double
}

/// Ground-space strides follow actual displacement, never input or frame rate.
public struct RobotStride: Sendable {
    private var previous: Vector?
    private var remainder = 0.0
    private var left = true
    public private(set) var distance = 0.0
    public private(set) var moving = false
    public private(set) var direction = Vector()
    private let spacing = 0.025
    public init() {}

    public mutating func advance(to position: Vector) -> [RobotFootstep] {
        defer { previous = position }
        guard let previous else { return [] }
        let delta = position - previous
        let length = delta.length
        moving = length > 0.000001 && length < 0.25
        guard moving else {
            if length >= 0.25 { remainder = 0 }
            return []
        }
        direction = delta.normalized
        distance += length
        var steps: [RobotFootstep] = []
        var along = spacing - remainder
        while along <= length + 0.000000001 {
            steps.append(RobotFootstep(position: previous + direction * along,
                                      direction: direction, side: left ? -1 : 1))
            left.toggle()
            along += spacing
        }
        remainder = (remainder + length).truncatingRemainder(dividingBy: spacing)
        if remainder < 0.000000001 || spacing - remainder < 0.000000001 { remainder = 0 }
        return steps
    }
}
