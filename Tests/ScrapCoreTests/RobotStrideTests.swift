import Testing
@testable import ScrapCore

@Test func footprintSpacingIsIndependentOfFrameRateAndFeetAlternate() {
    var single = RobotStride(), split = RobotStride()
    _ = single.advance(to: Vector()); _ = split.advance(to: Vector())
    let long = single.advance(to: Vector(0.2, 0))
    let short = (1...40).flatMap { split.advance(to: Vector(Double($0) * 0.005, 0)) }
    #expect(long.count == 8 && short.count == 8)
    for (a, b) in zip(long, short) {
        #expect((a.position - b.position).length < 0.00000001)
        #expect(a.side == b.side)
    }
    #expect(long.map(\.side) == [-1, 1, -1, 1, -1, 1, -1, 1])
}

@Test func stationaryAndTeleportingRobotsLeaveNoSteps() {
    var stride = RobotStride()
    #expect(stride.advance(to: Vector(0.5, 0.5)).isEmpty)
    #expect(stride.advance(to: Vector(0.5, 0.5)).isEmpty)
    #expect(!stride.moving)
    #expect(stride.advance(to: Vector(1, 1)).isEmpty)
    #expect(!stride.moving)
    #expect(stride.advance(to: Vector(1, 1.025)).count == 1)
    #expect(stride.direction == Vector(0, 1))
    let distance = stride.distance
    #expect(stride.advance(to: Vector(1, 1.025)).isEmpty)
    #expect(!stride.moving && stride.distance == distance)
}
