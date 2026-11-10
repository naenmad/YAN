import SwiftUI

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
        
        // Sengaja bleed 3pt ke atas (rect.minY - 3) agar menempel rapat tanpa celah di bezel fisik layar
        let bleedTop = rect.minY - 3.0
        
        // 0. Mulai dari atas bezel kiri
        path.move(to: CGPoint(x: rect.minX, y: bleedTop))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        
        // 1. Lengkungan telinga kiri (ear curve)
        if ear > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + ear, y: rect.minY + ear),
                control: CGPoint(x: rect.minX + ear, y: rect.minY)
            )
        } else {
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        }
        
        // 2. Garis vertikal sisi kiri ke bawah
        path.addLine(to: CGPoint(x: rect.minX + ear, y: rect.maxY - corner))
        
        // 3. Lengkungan sudut bawah kiri (bottom-left corner)
        if corner > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + ear + corner, y: rect.maxY),
                control: CGPoint(x: rect.minX + ear, y: rect.maxY)
            )
        }
        
        // 4. Garis horizontal bawah
        path.addLine(to: CGPoint(x: rect.maxX - ear - corner, y: rect.maxY))
        
        // 5. Lengkungan sudut bawah kanan (bottom-right corner)
        if corner > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - ear, y: rect.maxY - corner),
                control: CGPoint(x: rect.maxX - ear, y: rect.maxY)
            )
        }
        
        // 6. Garis vertikal sisi kanan ke atas
        path.addLine(to: CGPoint(x: rect.maxX - ear, y: rect.minY + ear))
        
        // 7. Lengkungan telinga kanan (ear curve)
        if ear > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY),
                control: CGPoint(x: rect.maxX - ear, y: rect.minY)
            )
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
        
        // 8. Menutup kembali ke atas bezel kanan
        path.addLine(to: CGPoint(x: rect.maxX, y: bleedTop))
        path.closeSubpath()
        
        return path
    }
}
