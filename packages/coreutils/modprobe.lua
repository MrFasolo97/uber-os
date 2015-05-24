--Modprobe
argv = { ... }
if #argv == 0 then
    print("Usage: modprobe <module1> [module2] ...")
    return
end

for i = 1, #argv do
    kernel.loadModule(argv[i], false)
end
