import SwiftUI
import AppKit

public struct NotchHardwareHUDView: View {
    @ObservedObject private var stats = SystemStatsManager.shared
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 12) {
            // SISI KIRI: Compute & Memory (CPU & RAM)
            VStack(spacing: 8) {
                // CPU Gauge Card
                HStack(spacing: 9) {
                    ZStack {
                        Circle()
                            .fill(Color.cyan.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "cpu")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.cyan)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("CPU")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                            Text(String(format: "%.0f%%", stats.cpuUsage))
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.10))
                                Capsule()
                                    .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: max(4, geo.size.width * CGFloat(stats.cpuUsage / 100.0)))
                            }
                        }
                        .frame(height: 4)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                // RAM Gauge Card
                HStack(spacing: 9) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.18))
                            .frame(width: 32, height: 32)
                        Image(systemName: "memorychip")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.purple)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("RAM")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                            Text(String(format: "%.1f / %.0f GB", stats.ramUsedGB, stats.ramTotalGB))
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.70))
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.10))
                                Capsule()
                                    .fill(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: max(4, geo.size.width * CGFloat(stats.ramPercentage / 100.0)))
                            }
                        }
                        .frame(height: 4)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .frame(maxWidth: .infinity)
            
            // DIVIDER TENGAH
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 1)
                .padding(.vertical, 4)
            
            // SISI KANAN: Power & Battery Telemetry
            VStack(spacing: 8) {
                // Battery Card
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(stats.isCharging ? Color.green.opacity(0.18) : Color.white.opacity(0.08))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: stats.isCharging ? "bolt.batteryblock.fill" : "battery.100")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(stats.isCharging ? .green : .white.opacity(0.85))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("\(stats.batteryLevel)%")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(stats.isCharging ? .green : .white)
                            
                            if stats.isCharging {
                                Text("CHARGING")
                                    .font(.system(size: 7, weight: .heavy))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.green)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Text(stats.powerSource)
                            .font(.system(size: 8.5, weight: .medium))
                            .foregroundColor(.white.opacity(0.45))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                // System Status / Low Power Mode Card
                HStack(spacing: 8) {
                    Image(systemName: stats.isLowPowerMode ? "leaf.fill" : "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(stats.isLowPowerMode ? .yellow : .cyan)
                    
                    Text(stats.isLowPowerMode ? "Low Power Mode Active" : "Normal Performance")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.70))
                    
                    Spacer()
                    
                    Circle()
                        .fill(stats.isLowPowerMode ? Color.yellow : Color.green)
                        .frame(width: 6, height: 6)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Compact Hover Hardware HUD View (Mode Hover 56pt)

public struct NotchCompactHardwareHUDView: View {
    @ObservedObject private var stats = SystemStatsManager.shared
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 12) {
            // CPU Chip
            HStack(spacing: 5) {
                Image(systemName: "cpu")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.cyan)
                Text(String(format: "CPU %.0f%%", stats.cpuUsage))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.05))
            .clipShape(Capsule())
            
            // RAM Chip
            HStack(spacing: 5) {
                Image(systemName: "memorychip")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.purple)
                Text(String(format: "RAM %.1fG", stats.ramUsedGB))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.05))
            .clipShape(Capsule())
            
            // Battery Chip
            HStack(spacing: 5) {
                Image(systemName: stats.isCharging ? "bolt.fill" : "battery.100")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(stats.isCharging ? .green : .white)
                Text("\(stats.batteryLevel)%")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(stats.isCharging ? .green : .white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.05))
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
