--UberOS bedrock loader
--Why? Because we can!
--Seriously. Bedrock is not made for UNIX-like file structure
--At least yet.
--Ok, here we go!

local bedrockPath = "/usr/include/bedrock"
os.loadAPI(bedrockPath .. "/Bedrock")
if Bedrock then
    Bedrock.BasePath = bedrockPath
    local oldBedrockInitialise = Bedrock.Initialise
    Bedrock.Initialise = function(self, path)
        Bedrock.ProgramPath = path or shell.getRunningProgram()
        local x = oldBedrockInitialise(self)
        Bedrock.ProgramPath = nil
        return x
    end
end
