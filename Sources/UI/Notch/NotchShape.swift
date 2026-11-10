import SwiftUI

/// Bentuk penuh Notch untuk background fill dan hit testing (termasuk bleed ke atas bezel)
public struct NotchShape: Shape {
    public var cornerRadius: Double
    public var earRadius: Double
    
    public var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(cornerRadius, earRadius) }
        set {
            cornerRadius = newValue.first
            earRadius = newValue.second
        }
    }
    
    public init(cornerRadius: Double = 14.0, earRadius: Double = 6.0) {
        self.cornerRadius = cornerRadius
        self.earRadius = earRadius
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let ear = max(0, min(earRadius, min(rect.width / 4, rect.height / 2)))
        let corner = max(0, min(cornerRadius, min((rect.width - 2 * ear) / 2, rect.height - ear)))
        let bleedTop = rect.minY - 3.0
        
        path.move(to: CGPoint(x: rect.minX, y: bleedTop))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        
        if ear > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + ear, y: rect.minY + ear),
                control: CGPoint(x: rect.minX + ear, y: rect.minY)
            )
        } else {
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        }
        
        path.addLine(to: CGPoint(x: rect.minX + ear, y: rect.maxY - corner))
        
        if corner > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + ear + corner, y: rect.maxY),
                control: CGPoint(x: rect.minX + ear, y: rect.maxY)
            )
        }
        
        path.addLine(to: CGPoint(x: rect.maxX - ear - corner, y: rect.maxY))
        
        if corner > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - ear, y: rect.maxY - corner),
                control: CGPoint(x: rect.maxX - ear, y: rect.maxY)
            )
        }
        
        path.addLine(to: CGPoint(x: rect.maxX - ear, y: rect.minY + ear))
        
        if ear > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY),
                control: CGPoint(x: rect.maxX - ear, y: rect.minY)
            )
        }
        
        path.addLine(to: CGPoint(x: rect.maxX, y: bleedTop))
        path.closeSubpath()
        
        return path
    }
}

/// Bentuk garis tepi (Outline) untuk menonjolkan siluet notch di atas menu bar hitam / full-screen
public struct NotchBorderShape: Shape {
    public var cornerRadius: Double
    public var earRadius: Double
    
    public var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(cornerRadius, earRadius) }
        set {
            cornerRadius = newValue.first
            earRadius = newValue.second
        }
    }
    
    public init(cornerRadius: Double = 14.0, earRadius: Double = 6.0) {
        self.cornerRadius = cornerRadius
        self.earRadius = earRadius
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let ear = max(0, min(earRadius, min(rect.width / 4, rect.height / 2)))
        let corner = max(0, min(cornerRadius, min((rect.width - 2 * ear) / 2, rect.height - ear)))
        
        // Mulai dari ujung kiri atas (tanpa garis atas, agar bagian atas tetap menyatu dengan bezel)
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        
        // 1. Telinga kiri
        if ear > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + ear, y: rect.minY + ear),
                control: CGPoint(x: rect.minX + ear, y: rect.minY)
            )
        }
        
        // 2. Garis sisi kiri
        path.addLine(to: CGPoint(x: rect.minX + ear, y: rect.maxY - corner))
        
        // 3. Sudut lengkung bawah kiri
        if corner > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + ear + corner, y: rect.maxY),
                control: CGPoint(x: rect.minX + ear, y: rect.maxY)
            )
        }
        
        // 4. Garis bawah horizontal
        path.addLine(to: CGPoint(x: rect.maxX - ear - corner, y: rect.maxY))
        
        // 5. Sudut lengkung bawah kanan
        if corner > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - ear, y: rect.maxY - corner),
                control: CGPoint(x: rect.maxX - ear, y: rect.maxY)
            )
        }
        
        // 6. Garis sisi kanan
        path.addLine(to: CGPoint(x: rect.maxX - ear, y: rect.minY + ear))
        
        // 7. Telinga kanan ke tepi atas
        if ear > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY),
                control: CGPoint(x: rect.maxX - ear, y: rect.minY)
            )
        }
        
        return path
    }
}
