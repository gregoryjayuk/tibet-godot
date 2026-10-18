// dk-thermal: print the Mac's thermal state, Low Power Mode and power source, once at start and then every N seconds
// (default 5), one line each: "thermal=nominal lowpower=0 battery=0 t=1790000000". Godot's OS class exposes none of
// these, so Quality starts this helper with OS.execute_with_pipe and reads its lines (plan chapter 11, 21.3).
// Build: swiftc -O -o tools/bin/dk-thermal tools/thermal/dk-thermal.swift   (tools/thermal/build.sh does it)
// It exits when its reader goes away (a write to a closed pipe ends it).
import Foundation
import IOKit.ps

func thermalName(_ s: ProcessInfo.ThermalState) -> String {
    switch s {
    case .nominal: return "nominal"
    case .fair: return "fair"
    case .serious: return "serious"
    case .critical: return "critical"
    @unknown default: return "unknown"
    }
}

func onBattery() -> Bool {
    guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
          let source = IOPSGetProvidingPowerSourceType(info)?.takeUnretainedValue() else { return false }
    return (source as String) == kIOPMBatteryPowerKey
}

let interval = CommandLine.arguments.count > 1 ? (Double(CommandLine.arguments[1]) ?? 5.0) : 5.0
while true {
    let p = ProcessInfo.processInfo
    print("thermal=\(thermalName(p.thermalState)) lowpower=\(p.isLowPowerModeEnabled ? 1 : 0) battery=\(onBattery() ? 1 : 0) t=\(Int(Date().timeIntervalSince1970))")
    fflush(stdout)
    Thread.sleep(forTimeInterval: interval)
}
