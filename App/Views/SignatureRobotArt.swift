import UIKit
import ScrapCore

// Original vector skins, rendered once per pose and shared by portraits and SpriteKit.
@MainActor enum SignatureRobotArt {
    private static var cache: [String: UIImage] = [:]
    static func image(_ skin: String, frame: Int = 0, victory: Bool = false) -> UIImage {
        let key = "\(skin)-\(frame % 4)-\(victory)"
        if let image = cache[key] { return image }
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 512, height: 512), format: format).image { renderer in
            let c = renderer.cgContext
            c.setLineJoin(.round)
            let ink = UIColor(hex: "10252D"), gold = UIColor(hex: "FFBD55"), blue = UIColor(hex: "83B9FF"), pink = UIColor(hex: "F6B8DF"), mint = UIColor(hex: "A5FFE1")
            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: UIColor, _ radius: CGFloat = 12) {
                let path = UIBezierPath(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: radius)
                color.setFill(); path.fill(); ink.setStroke(); path.lineWidth = 6; path.stroke()
            }
            func oval(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: UIColor) {
                color.setFill(); UIBezierPath(ovalIn: CGRect(x: x, y: y, width: w, height: h)).fill()
            }
            func polygon(_ points: [CGPoint], _ color: UIColor) {
                let p = UIBezierPath(); p.move(to: points[0]); for point in points.dropFirst() { p.addLine(to: point) }; p.close()
                color.setFill(); p.fill(); ink.setStroke(); p.lineWidth = 6; p.stroke()
            }
            let tint = skin == "ronin" ? gold : skin == "bastion" ? blue : pink
            let stride: CGFloat = victory ? 0 : [0, 8, 0, -8][frame % 4]
            oval(119, 444, 275, 32, ink.withAlphaComponent(0.18))
            if skin == "medic" {
                for side in [CGFloat(-1), CGFloat(1)] {
                    polygon([CGPoint(x: 256 + side * 57, y: 256), CGPoint(x: 256 + side * 193, y: 184), CGPoint(x: 256 + side * 176, y: 307), CGPoint(x: 256 + side * 72, y: 337)], mint)
                    rect(256 + side * 144 - 14, 220, 28, 69, .white, 8)
                }
                mint.setStroke(); let halo = UIBezierPath(ovalIn: CGRect(x: 161, y: 60, width: 190, height: 34)); halo.lineWidth = 12; halo.stroke()
            }
            if skin == "ronin" {
                polygon([CGPoint(x: 154,y: 241),CGPoint(x: 122,y: 389),CGPoint(x: 214,y: 367),CGPoint(x: 262,y: 246)], UIColor(hex:"A43D47"))
                polygon([CGPoint(x: 375,y: 164),CGPoint(x: 404,y: 183),CGPoint(x: 326,y: 385),CGPoint(x: 303,y: 373)], UIColor(hex:"E9F5F8"))
                rect(298, 353, 64, 18, gold, 5)
            }
            rect(179, 347 + stride, 64, 92, UIColor(hex:"304957"))
            rect(269, 347 - stride, 64, 92, UIColor(hex:"304957"))
            rect(163, 411 + stride, 86, 37, tint)
            rect(263, 411 - stride, 86, 37, tint)
            let armY: CGFloat = victory ? 152 : 258 + stride
            rect(121, armY, 53, 111, tint, 18); rect(338, victory ? 152 : 258 - stride, 53, 111, tint, 18)
            rect(166, 224, 180, 147, tint, skin == "bastion" ? 18 : 38)
            rect(188, 255, 136, 57, UIColor(hex:"293F50"), 14)
            rect(195, 326, 122, 20, tint == pink ? mint : .white, 5)
            if skin == "bastion" {
                rect(95, 214, 92, 61, blue, 14); rect(325, 214, 92, 61, blue, 14)
                polygon([CGPoint(x: 333,y: 270),CGPoint(x: 430,y: 259),CGPoint(x: 440,y: 358),CGPoint(x: 382,y: 407),CGPoint(x: 327,y: 355)], UIColor(hex:"4866AD"))
                polygon([CGPoint(x: 350,y: 294),CGPoint(x: 408,y: 287),CGPoint(x: 411,y: 343),CGPoint(x: 381,y: 373),CGPoint(x: 349,y: 342)], blue)
                rect(136, 117, 240, 113, blue, 18)
                rect(189, 92, 134, 38, UIColor(hex:"D8E9FF"), 9)
            } else {
                rect(161, 115, 190, 123, tint, 36)
            }
            rect(178, 150, 156, 65, ink, 22)
            oval(202, 167, 24, 23, mint); oval(286, 167, 24, 23, mint)
            mint.setStroke(); let mouth = UIBezierPath(); mouth.move(to: CGPoint(x: 238,y: 195)); mouth.addQuadCurve(to: CGPoint(x: 276,y: 195), controlPoint: CGPoint(x: 256,y: victory ? 217 : 205)); mouth.lineWidth = 5; mouth.stroke()
            if skin == "ronin" {
                polygon([CGPoint(x: 162,y: 142),CGPoint(x: 134,y: 81),CGPoint(x: 210,y: 116),CGPoint(x: 256,y: 91),CGPoint(x: 300,y: 116),CGPoint(x: 376,y: 81),CGPoint(x: 350,y: 142)], gold)
                oval(238, 111, 36, 36, UIColor(hex:"E97043"))
                polygon([CGPoint(x: 230,y: 268),CGPoint(x: 268,y: 268),CGPoint(x: 245,y: 291),CGPoint(x: 278,y: 291),CGPoint(x: 237,y: 320)], gold)
            } else if skin == "medic" {
                rect(237, 103, 38, 53, .white, 5); rect(228, 118, 56, 20, .white, 4)
                rect(246, 263, 20, 43, mint, 3); rect(234, 275, 44, 19, mint, 3)
            } else {
                rect(229, 269, 54, 35, UIColor(hex:"D8E9FF"), 8)
                for x in [CGFloat(190), CGFloat(310)] { oval(x, 232, 12, 12, .white) }
            }
        }
        cache[key] = image; return image
    }
}
