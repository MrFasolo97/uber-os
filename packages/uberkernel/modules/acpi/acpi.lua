acpi = {}

local nativeShutdown = os.shutdown
local nativeReboot = os.reboot

function acpi.shutdown()
    if thread and thread.getUID(coroutine.running()) ~= 0 then
        return
    end
    kernel.log("Sending SIGTERM to all processes")
    for k, v in pairs(thread.getRunningThreads()) do
        thread.kill(v.pid, "TERM")
    end
    kernel.doHook("acpi_shutdown")
    nativeShutdown()
end

function acpi.reboot()
    if thread and thread.getUID(coroutine.running()) ~= 0 then
        return
    end
    kernel.log("Sending SIGTERM to all processes")
    for k, v in pairs(thread.getRunningThreads()) do
        thread.kill(v.pid, "TERM")
    end
    kernel.doHook("acpi_reboot")
    nativeReboot()
end

os.shutdown = acpi.shutdown
os.reboot = acpi.reboot

acpi = applyreadonly(acpi) _G["acpi"] = acpi
