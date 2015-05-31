if thread and thread.getUID(coroutine.running()) ~= 0 then
    return
end
kernel.log("Sending SIGTERM to all processes")
for k, v in pairs(thread.getRunningThreads()) do
    thread.kill(v.pid, "TERM")
end
kernel.log("Running acpi_shutdown hook")
kernel.doHook("acpi_shutdown")
kernel.log("Sending SIGKILL to all processes")
for k, v in pairs(thread.getRunningThreads()) do
    thread.kill(v.pid, "KILL")
end
