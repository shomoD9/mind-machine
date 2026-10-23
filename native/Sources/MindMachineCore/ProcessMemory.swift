/* Runtime footprint diagnostics used by the keyboard and Release benchmark.
 OS headroom is dynamic; this reports the actual process rather than assuming a
 universal iOS extension limit. The keyboard records a sample after rendering. */
import Foundation
import Darwin
import os

public struct ProcessMemory: Codable, Sendable {
    public let footprintMiB: Double
    public let availableMiB: Double?
    public static func sample() -> ProcessMemory? {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let code = withUnsafeMutablePointer(to: &info) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        guard code == KERN_SUCCESS else { return nil }
        #if os(iOS)
        let available: Double? = Double(os_proc_available_memory())/1048576
        #else
        let available: Double? = nil // macOS does not expose the iOS jetsam budget.
        #endif
        return ProcessMemory(footprintMiB: Double(info.phys_footprint)/1048576, availableMiB: available)
    }
}
