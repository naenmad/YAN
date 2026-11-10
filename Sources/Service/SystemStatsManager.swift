import Foundation
import AppKit
import Darwin
import IOKit.ps

@MainActor
public final class SystemStatsManager: ObservableObject {
    public static let shared = SystemStatsManager()
    
    // CPU
    @Published public var cpuUsage: Double = 0.0 // 0 - 100%
    
    // RAM
    @Published public var ramUsedGB: Double = 0.0
    @Published public var ramTotalGB: Double = 8.0
    @Published public var ramPercentage: Double = 0.0
    
    // Battery
    @Published public var batteryLevel: Int = 100
    @Published public var isCharging: Bool = false
    @Published public var powerSource: String = "Battery"
    @Published public var isLowPowerMode: Bool = false
    
    private var timer: Timer?
    private var prevCpuTicks: (user: UInt32, system: UInt32, idle: UInt32, nice: UInt32)?
    
    private init() {
        self.ramTotalGB = Double(ProcessInfo.processInfo.physicalMemory) / (1024 * 1024 * 1024)
        updateAll()
        startMonitoring()
    }
    
    public func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateAll()
            }
        }
    }
    
    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    public func updateAll() {
        updateCPU()
        updateRAM()
        updateBattery()
        self.isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
    }
    
    // MARK: - CPU Calculation
    
    private func updateCPU() {
        var cpuLoad = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &cpuLoad) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return }
        
        let user = cpuLoad.cpu_ticks.0
        let system = cpuLoad.cpu_ticks.1
        let idle = cpuLoad.cpu_ticks.2
        let nice = cpuLoad.cpu_ticks.3
        
        if let prev = prevCpuTicks {
            let deltaUser = user >= prev.user ? user - prev.user : 0
            let deltaSystem = system >= prev.system ? system - prev.system : 0
            let deltaIdle = idle >= prev.idle ? idle - prev.idle : 0
            let deltaNice = nice >= prev.nice ? nice - prev.nice : 0
            
            let total = deltaUser + deltaSystem + deltaIdle + deltaNice
            let usage = deltaUser + deltaSystem + deltaNice
            
            if total > 0 {
                self.cpuUsage = min(100.0, max(0.0, Double(usage) / Double(total) * 100.0))
            }
        }
        
        prevCpuTicks = (user, system, idle, nice)
    }
    
    // MARK: - RAM Calculation
    
    private func updateRAM() {
        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return }
        
        let pageSize = Double(vm_kernel_page_size)
        let active = Double(vmStats.active_count) * pageSize / (1024 * 1024 * 1024)
        let wired = Double(vmStats.wire_count) * pageSize / (1024 * 1024 * 1024)
        let compressed = Double(vmStats.compressor_page_count) * pageSize / (1024 * 1024 * 1024)
        
        let used = active + wired + compressed
        self.ramUsedGB = used
        self.ramPercentage = min(100.0, max(0.0, (used / ramTotalGB) * 100.0))
    }
    
    // MARK: - Battery Calculation
    
    private func updateBattery() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else { return }
        guard let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef], !sources.isEmpty else { return }
        
        for source in sources {
            if let desc = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] {
                if let cap = desc[kIOPSCurrentCapacityKey] as? Int {
                    self.batteryLevel = cap
                }
                if let charging = desc[kIOPSIsChargingKey] as? Bool {
                    self.isCharging = charging
                }
                if let pState = desc[kIOPSPowerSourceStateKey] as? String {
                    self.powerSource = pState == kIOPSACPowerValue ? "AC Power" : "Battery"
                }
                break
            }
        }
    }
}
