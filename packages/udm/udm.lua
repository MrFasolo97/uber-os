thread.registerSignal("INT", function() end)

term.redirect(term.native())
term.clear()

local ccute = lua.include("libccute")

local app = ccute.Application()

local loginLabel, passwordLabel, loginInput, passwordInput, loginButton, loginButtonLabel
local mainLayout, loginLayout, passwordLayout

loginLabel = ccute.Label(app, "Login:")

passwordLabel = ccute.Label(app, "Password:")

loginInput = ccute.Input(app)
loginInput.maxHeight = 1

passwordInput = ccute.Input(app)
passwordInput.mask = "*"
passwordInput.maxHeight = 1

mainLayout = ccute.VerticalLayout(app)
mainLayout.topMargin = 1
mainLayout.bottomMargin = 1
mainLayout.leftMargin = 1
mainLayout.rightMargin = 1
app:attachWidget(mainLayout)

loginLayout = ccute.HorizontalLayout(app)
loginLayout.maxHeight = 1
passwordLayout = ccute.HorizontalLayout(app)
passwordLayout.maxHeight = 1

mainLayout:addChild(loginLayout)
mainLayout:addChild(passwordLayout)

loginLayout:addChild(loginLabel)
loginLayout:addChild(loginInput)

passwordLayout:addChild(passwordLabel)
passwordLayout:addChild(passwordInput)

loginButton = ccute.Button(app)
loginButton.onclick = function(self)
    local username = loginInput.text
    local password = passwordInput.text
    if users.login(username, password) then
        term.clear()
        kernel.log("Logging in as " .. username)
        thread.runFile(users.getShell(users.getUIDByUsername(username)),
        nil, true, users.getUIDByUsername(username))
        loginInput.text = ""
        passwordInput.text = ""
        loginInput.cursorPos = 1
        passwordInput.cursorPos = 1
        loginInput.cursorPos = 1
        passwordInput.cursorPos = 1
        loginInput.leftBorder = 1
        passwordInput.leftBorder = 1
        app.renderer.lastSurface = nil
        loginButton.pressed = false
    else
        loginInput.text = ""
        passwordInput.text = ""
    end
end

loginButtonLabel = ccute.Label(app, "Login")
loginButtonLabel.textColor = colors.black
loginButton:addChild(loginButtonLabel)

loginButtonLabel:resize(5, 1)

loginButton.maxHeight = 3

mainLayout:addChild(loginButton)
mainLayout:recalculate()

loginButtonLabel:move(math.floor(loginButton.width / 2 - 3), math.floor(loginButton.height / 2 + 1))

app:run(true)
