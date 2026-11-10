import SwiftUI
import AppKit

// MARK: - NotchHardwareHUDView (Mode Clicked / 152pt)

public struct NotchHardwareHUDView: View {
    @ObservedObject private var stats = SystemStatsManager.shared
    @ObservedObject private var store = NotchSettingsStore.shared
    
    public init() {}
    
    public var body: some View {
        let currentW = CGFloat(store.preferences.clickedWidth)
        let currentH = CGFloat(store.preferences.clickedHeight)
        let availableW = max(360.0, currentW - 53)
        let leftWidth = max(230.0, availableW * 0.54)
        let rightWidth = max(190.0, availableW - leftWidth)
        let dividerHeight = max(70.0, currentH - 32)
        
        HStack(spacing: 12) {
            // SISI KIRI: Compute & Memory (CPU & RAM)
            VStack(alignment: .leading, spacing: 10) {
                // Header Sisi Kiri
                HStack(spacing: 5) {
                    Image(systemName: "cpu")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.cyan)
                    Text("APPLE SILICON COMPUTE")
                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        .tracking(0.8)
                        .foregroundColor(.white.opacity(0.85))
                    
                    Spacer()
                    
                    // Live Activity Pulse Dot
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 4.5, height: 4.5)
                        .shadow(color: Color.cyan.opacity(0.6), radius: 2)
                }
                
                // 1. CPU Load Telemetry Row
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("CPU Load")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(String(format: "%.0f%%", stats.cpuUsage))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                    
                    // Continuous Sleek Gradient Capsule
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.cyan.opacity(0.85), Color.blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(4, geo.size.width * CGFloat(min(1.0, stats.cpuUsage / 100.0))))
                        }
                    }
                    .frame(height: 5)
                    
                    HStack {
                        Text("Darwin Core Host")
                            .font(.system(size: 8, weight: .regular))
                            .foregroundColor(.white.opacity(0.35))
                        Spacer()
                        Text("\(ProcessInfo.processInfo.activeProcessorCount) Cores Active")
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.40))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.035))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                
                // 2. RAM Memory Telemetry Row
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Unified Memory")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(String(format: "%.1f / %.0f GB", stats.ramUsedGB, stats.ramTotalGB))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.90))
                    }
                    
                    // Continuous Sleek Memory Capsule
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.purple.opacity(0.85), Color.pink.opacity(0.85)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(4, geo.size.width * CGFloat(min(1.0, stats.ramPercentage / 100.0))))
                        }
                    }
                    .frame(height: 5)
                    
                    HStack {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(stats.ramPercentage > 85 ? Color.orange : Color.green)
                                .frame(width: 4, height: 4)
                            Text("Memory Pressure: Nominal")
                                .font(.system(size: 8, weight: .regular))
                                .foregroundColor(.white.opacity(0.35))
                        }
                        Spacer()
                        Text(String(format: "%.0f%% Used", stats.ramPercentage))
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.40))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.035))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            }
            .frame(width: leftWidth)
            
            // DIVIDER TENGAH (Identik dengan Dashboard)
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 1, height: dividerHeight)
            
            // SISI KANAN: Power, Battery & Energy Architecture
            VStack(alignment: .leading, spacing: 8) {
                // Header Sisi Kanan
                HStack(spacing: 5) {
                    Image(systemName: "bolt.batteryblock")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.green)
                    Text("ENERGY & BATTERY")
                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        .tracking(0.8)
                        .foregroundColor(.white.opacity(0.85))
                    
                    Spacer()
                    
                    Text(stats.powerSource)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.45))
                }
                
                // Battery Metric Large Readout
                HStack(alignment: .center, spacing: 12) {
                    // Big percentage
                    Text("\(stats.batteryLevel)%")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(stats.isCharging ? .green : .white)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        if stats.isCharging {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 8, weight: .black))
                                Text("CHARGING")
                                    .font(.system(size: 8, weight: .heavy))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1.5)
                            .background(Color.green)
                            .clipShape(Capsule())
                        } else {
                            Text("Battery Power")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        
                        Text(stats.isCharging ? "Connected to Power" : "Discharging Normally")
                            .font(.system(size: 8, weight: .regular))
                            .foregroundColor(.white.opacity(0.40))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.035))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                
                // Segmented 10-Bar Apple Battery Level Indicator
                HStack(spacing: 3) {
                    ForEach(0..<10, id: \.self) { idx in
                        let isActive = Double(idx) < Double(stats.batteryLevel) / 10.0
                        RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                            .fill(isActive ? (stats.isCharging ? Color.green : Color.white) : Color.white.opacity(0.10))
                            .frame(height: 6)
                    }
                }
                .padding(.horizontal, 2)
                
                // Thermal & Power Efficiency Status Chip
                HStack(spacing: 6) {
                    Image(systemName: "gauge.with.needle")
                        .font(.system(size: 9))
                        .foregroundColor(stats.isLowPowerMode ? .yellow : .cyan)
                    
                    Text("Thermal: Nominal")
                        .font(.system(size: 8.5, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.60))
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(stats.isLowPowerMode ? Color.yellow : Color.green)
                            .frame(width: 4, height: 4)
                        Text(stats.isLowPowerMode ? "Low Power" : "High Perf")
                            .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                            .foregroundColor(stats.isLowPowerMode ? .yellow : .white.opacity(0.80))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.025))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .frame(width: rightWidth)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
    }
}

// MARK: - Compact Hover Hardware HUD View (Mode Hover 56pt)

public struct NotchCompactHardwareHUDView: View {
    @ObservedObject private var stats = SystemStatsManager.shared
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 12) {
            // CPU Readout
            HStack(spacing: 5) {
                Image(systemName: "cpu")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.cyan)
                Text(String(format: "CPU %.0f%%", stats.cpuUsage))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: 12)
            
            // RAM Readout
            HStack(spacing: 5) {
                Image(systemName: "memorychip")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                Text(String(format: "RAM %.1fG", stats.ramUsedGB))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: 12)
            
            // Battery Readout
            HStack(spacing: 5) {
                Image(systemName: stats.isCharging ? "bolt.fill" : "battery.100")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(stats.isCharging ? .green : .white)
                Text("\(stats.batteryLevel)%")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(stats.isCharging ? .green : .white)
            }
            
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
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
