import "CoreLibs/graphics"
import "CoreLibs/timer"
import "CoreLibs/object"
import "../../funkin/music/bopper"
import "../mainmenu/mainmenustate"

local gfx <const> = playdate.graphics

class("TitleState").extends()

function TitleState:init(conductor, audioPlayer, funkinPath, gfDanceTitle, gfRingTone, confirm, phantomMuffFont, introTexts, mainMenuState, skipIntro)
    TitleState.super.init(self)
    self.mainMenuState = mainMenuState 
    self.bopper = Bopper(conductor)

    gfx.setFont(phantomMuffFont)

    self.conductor = conductor
    self.introMusic = audioPlayer
    self.canActivateCheatCode = false

    self.funkinImage = playdate.graphics.image.new(funkinPath)
    if not self.funkinImage then
        error("Error: Could not load funkin image at path: " .. funkinPath)
    end

    self.gfDanceTable = playdate.graphics.imagetable.new(gfDanceTitle)
    if not self.gfDanceTable then
        error("Error: Could not load gfDance imagetable at path: " .. gfDanceTitle)
    end

    if not gfRingTone or gfRingTone == "" then
        error("Error: gfRingTone must be a valid path")
    else
        self.gfRingTone = gfRingTone
    end

    if not confirm or confirm == "" then
        error("Error: confirm must be a valid path")
    else
        self.confirm = confirm
    end

    self.gfScale = 0.28
    self.gfX = 305
    self.gfY = 180
    self.gfCurrentFrame = 1
    self.gfAnimationSpeed = 0.0215

    self.gfAnimationTimer = playdate.timer.keyRepeatTimerWithDelay(
        self.gfAnimationSpeed * 1000,
        self.gfAnimationSpeed * 1000,
        function()
            self.gfCurrentFrame += 1
            if self.gfCurrentFrame > self.gfDanceTable:getLength() then
                self.gfCurrentFrame = 1
            end
        end
    )

    self.showingImage = false
    self.imageX = 97
    self.imageY = 118
    self.imageScale = 1.0

    gfx.setFont(self.phantomMuffFont)

    
    self.introTexts = self:readIntroTexts(introTexts)
    if #self.introTexts == 0 then
        error("Error: Intro texts file is empty or could not be read")
    end

    
    if not skipIntro then
        self.textLines = {
            {beat = 1.0, action = function() self:createCoolText({"Lyrabyte"}) end},
            {beat = 2.4, action = function() self:addMoreText("presents") end},
            {beat = 3.3, action = function() self:deleteCoolText() end},
            {beat = 4.01, action = function() self:createCoolText({"A Port", "of"}) end},
            {beat = 5.6, action = function() self:showImage() end},
            {beat = 6.4, action = function() self:deleteCoolText(); self:hideImage() end},
            {beat = 7.31, action = function() 
                local randomIntroText = self.introTexts[math.random(#self.introTexts)]
                self:addMoreText(randomIntroText[1] or "") 
            end},
            {beat = 8.98, action = function() 
                local randomIntroText = self.introTexts[math.random(#self.introTexts)]
                self:addMoreText(randomIntroText[2] or "") 
            end},
            {beat = 9.55, action = function() self:deleteCoolText() end},
            {beat = 10.35, action = function() self:addMoreText("Friday") end},
            {beat = 11.25, action = function() self:addMoreText("Night") end},
            {beat = 12.07, action = function() self:addMoreText("Crankin'") end},
            {beat = 13, action = function() self:skipIntro() end},
        }

        table.sort(self.textLines, function(a, b) return a.beat < b.beat end)

        self.nextBeatIndex = 1
        self.shownText = {}

        self.introMusic:play()

        self.bopper:setBopFrequencyMultiplier(0.02)

        self.flashActive = false
        self.canStart = false

        self.flashTriggered = false
        self.fadeImage = playdate.graphics.image.new(400, 240, playdate.graphics.kColorWhite)
        self.fadeImageOpacity = 1.0

        self.startMessageOpacity = 1.0
        self.startMessageFadeOut = true

        self.inputSequence = {}
        self.cheatCode = {
            playdate.kButtonLeft,
            playdate.kButtonRight,
            playdate.kButtonLeft,
            playdate.kButtonRight,
            playdate.kButtonUp,
            playdate.kButtonDown,
            playdate.kButtonUp,
            playdate.kButtonDown
        }
    else
        
        self.canStart = true
        self.transitionTriggered = false 
        self.bopper:setBopFrequencyMultiplier(1.3333333334)
        self:showImage()
        self.showGif = true
        self.canActivateCheatCode = true
        self:restartGfAnimationTimer()
    end
end

function TitleState:readIntroTexts(path)
    local texts = {}
    local file = playdate.file.open(path, playdate.file.kFileRead)
    if not file then
        print("Error: Could not open intro texts file at path: " .. path)
        return texts
    end

    while true do
        local line = file:readline()
        if not line then break end
        line = line:gsub("\n", ""):gsub("\r", "")
        if #line > 0 then
            
            local splitLines = {}
            for part in line:gmatch("[^%-%-]+") do
                table.insert(splitLines, part:match("^%s*(.-)%s*$")) 
            end
            table.insert(texts, splitLines)
        end
    end

    file:close()
    return texts
end

function TitleState:update()
    local gfx = playdate.graphics
    gfx.clear(gfx.kColorBlack)

    
    gfx.setFont(self.phantomMuffFont)

    self:checkCheatCode()

    local function restartMusic()
        self.introMusic:play()
    end
    
    self.introMusic:setFinishCallback(restartMusic)

    
    if playdate.buttonJustPressed(playdate.kButtonA) then
        if not self.canStart then
            print("Cannot start yet.")
            self:skipIntro()
            return
        end
        if self.transitionTriggered then
            print("Start process already initiated.")
            return
        end
        self.transitionTriggered = true 
        print("Button A pressed and canStart is true.")
        
        local confirmSound = playdate.sound.fileplayer.new(self.confirm)
        if confirmSound then
            confirmSound:setVolume(1.3)
            confirmSound:play()
            print("Playing confirm sound.")
        else
            print("Error: Unable to load confirm sound from:", self.confirm)
        end
        self:transitionToMainMenu()
        return
    end    

    
    local elapsedTime = playdate.getCurrentTimeMilliseconds()
    local beatDurationMs = self.conductor.stepLengthMs * 4
    local currentBeat = self.conductor.globalStep / 4 + 
                        (elapsedTime - self.conductor.lastStepTime) / beatDurationMs

    
    while self.nextBeatIndex <= #self.textLines do
        local beatData = self.textLines[self.nextBeatIndex]
        if currentBeat >= beatData.beat then
            self.bopper:setBopFrequencyMultiplier(0.4)
            beatData.action()
            self.nextBeatIndex = self.nextBeatIndex + 1
        else
            break
        end
    end

    
    gfx.setFont(gfx.getFont())
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)

    local y = 80
    for _, line in ipairs(self.shownText) do
        if type(line.text) == "string" then 
            gfx.drawTextAligned(line.text, 200, y, kTextAlignment.center)
        else
            print("Warning: Non-string text encountered:", line.text)
        end
        y += 20
    end
    
    if self.nextBeatIndex > #self.textLines then
        self:drawStartMessage()
    end

    
    self.bopper:update()

    if self.showingImage and self.funkinImage then
        local bump = self.bopper:getBumpValue()
        local adjustedScale = self.imageScale + bump

        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        self.funkinImage:drawScaled(self.imageX, self.imageY, adjustedScale)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    end

    if self.showGif and self.gfDanceTable then
        local frame = self.gfDanceTable:getImage(self.gfCurrentFrame)
        
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        local scaledWidth = frame.width * self.gfScale
        local scaledHeight = frame.height * self.gfScale
        frame:drawScaled(self.gfX - scaledWidth / 2, self.gfY - scaledHeight / 2, self.gfScale)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    end

    if self.flashActive then
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        self.fadeImage:drawFaded(0, 0, self.fadeImageOpacity, playdate.graphics.image.kDitherTypeBayer8x8)
        self.fadeImageOpacity -= 0.05
        if self.fadeImageOpacity <= 0 then
            self.flashActive = false
            self.fadeImageOpacity = 0
        end
    end
end

function TitleState:checkCheatCode()
    if not self.canActivateCheatCode then
        return
    end

    if playdate.buttonJustPressed(playdate.kButtonLeft) then
        table.insert(self.inputSequence, playdate.kButtonLeft)
    elseif playdate.buttonJustPressed(playdate.kButtonRight) then
        table.insert(self.inputSequence, playdate.kButtonRight)
    elseif playdate.buttonJustPressed(playdate.kButtonUp) then
        table.insert(self.inputSequence, playdate.kButtonUp)
    elseif playdate.buttonJustPressed(playdate.kButtonDown) then
        table.insert(self.inputSequence, playdate.kButtonDown)
    end

    if #self.inputSequence > #self.cheatCode then
        table.remove(self.inputSequence, 1)
    end

    if #self.inputSequence == #self.cheatCode then
        for i, button in ipairs(self.cheatCode) do
            if self.inputSequence[i] ~= button then
                return
            end
        end

        self:activateCheatCode()
        self.inputSequence = {}
    end
end

function TitleState:activateCheatCode()
    self.canActivateCheatCode = false
    self.flashTriggered = false
    self:startWhiteFlash()

    self:setAnimationSpeed(0.005)

    
    self.bopper:setBopFrequencyMultiplier(2) 

    self.introMusic:stop()

    
    if self.confirm and self.confirm ~= "" then
        local confirmSound = playdate.sound.fileplayer.new(self.confirm)
        confirmSound:setVolume(1.3)
        confirmSound:play()
    else
        print("Error: Confirm sound is not set or is invalid")
    end

    
    if self.gfRingTone and self.gfRingTone ~= "" then
        self.introMusic = playdate.sound.fileplayer.new(self.gfRingTone)
        self.introMusic:setVolume(0) 
        self.introMusic:play()

        
        self.fadeTimer = playdate.timer.new(100, function()
            local currentVolume = self.introMusic:getVolume()
            if currentVolume < 1 then
                self.introMusic:setVolume(currentVolume + 0.1)
            else
                self.fadeTimer:remove() 
                self.fadeTimer = nil
            end
        end)
        self.fadeTimer.repeats = true 
    else
        print("Error: gfRingTone is not set or is invalid")
    end
end

function TitleState:setAnimationSpeed(newSpeed)
    self.gfAnimationSpeed = newSpeed
    self.gfAnimationTimer:remove()
    self.gfAnimationTimer = playdate.timer.keyRepeatTimerWithDelay(
        self.gfAnimationSpeed * 1000,
        self.gfAnimationSpeed * 1000,
        function()
            self.gfCurrentFrame += 1
            if self.gfCurrentFrame > self.gfDanceTable:getLength() then
                self.gfCurrentFrame = 1
            end
        end
    )
end

function TitleState:drawStartMessage()
    local gfx = playdate.graphics

    
    if self.startMessageFadeOut then
        self.startMessageOpacity -= 0.05
        if self.startMessageOpacity <= 0 then
            self.startMessageFadeOut = false
            self.startMessageOpacity = 0
        end
    else
        self.startMessageOpacity += 0.05
        if self.startMessageOpacity >= 1 then
            self.startMessageFadeOut = true
            self.startMessageOpacity = 1
        end
    end

    
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.setDitherPattern(self.startMessageOpacity, gfx.image.kDitherTypeBayer8x8)

    
    drawScaledText("Press 'A' To Start", 100, 220, 0.8) 
end

function drawScaledText(text, x, y, scale)
    local gfx = playdate.graphics
    local font = gfx.getFont()
    
    
    local textWidth = font:getTextWidth(text)
    local textHeight = font:getHeight()

    
    local textImage = gfx.image.new(textWidth, textHeight)
    if not textImage then
        error("Failed to create image for text.")
    end
    
    
    gfx.pushContext(textImage)
    gfx.clear(gfx.kColorClear)
    gfx.drawText(text, 0, 0)
    gfx.popContext()
    
    
    local scaledImage = textImage:scaledImage(scale)
    if not scaledImage then
        error("Failed to scale the image.")
    end
    
    
    local scaledWidth = scaledImage.width
    local scaledHeight = scaledImage.height
    local drawX = x - scaledWidth / 2
    local drawY = y - scaledHeight / 2

    
    scaledImage:draw(drawX, drawY)
end

function TitleState:createCoolText(lines)
    
    for _, line in ipairs(lines) do
        table.insert(self.shownText, { text = line, font = gfx.getFont() })
    end
end

function TitleState:addMoreText(line)
    if type(line) == "string" then
        table.insert(self.shownText, { text = line, font = gfx.getFont() })
    elseif type(line) == "table" then
        for _, subLine in ipairs(line) do
            table.insert(self.shownText, { text = subLine, font = gfx.getFont() })
        end
    end
end

function TitleState:deleteCoolText()
    self.shownText = {}
end

function TitleState:showImage()
    self.showingImage = true
end

function TitleState:hideImage()
    self.showingImage = false
    self.imageScale = 1.1
end

function TitleState:skipIntro()
    self.conductor:resume()
    self.flashTriggered = false
    self.bopper:setBopFrequencyMultiplier(1.3333333334)
    self:deleteCoolText()
    self:hideImage()
    self.nextBeatIndex = #self.textLines + 1
    self.imageX = 0
    self.imageY = 0
    self:showImage()
    self:startWhiteFlash()
    self.showGif = true
    self.canActivateCheatCode = true
    self.canStart = true
    self.transitionTriggered = false 
    self:restartGfAnimationTimer() 
end

function TitleState:transitionToMainMenu()
    if not self.mainMenuState then
        error("Error: MainMenuState instance not found.")
    end
    
    self.mainMenuState:resetWipe()

    self.flashTriggered = false
    self:startWhiteFlash()

    gfx.clear(gfx.kColorBlack)

    playdate.timer.performAfterDelay(1000, function()
        gfx.clear(gfx.kColorBlack)

        
        currentState = self.mainMenuState
    end)
end

function TitleState:startWhiteFlash()
    if not self.flashTriggered then
        self.flashActive = true
        self.flashTriggered = true
        self.fadeImageOpacity = 1.0
    end
end

function TitleState:restartGfAnimationTimer()
    
    if self.gfAnimationTimer then
        self.gfAnimationTimer:remove()
    end

    
    self.gfAnimationTimer = playdate.timer.keyRepeatTimerWithDelay(
        self.gfAnimationSpeed * 1000,
        self.gfAnimationSpeed * 1000,
        function()
            self.gfCurrentFrame += 1
            if self.gfCurrentFrame > self.gfDanceTable:getLength() then
                self.gfCurrentFrame = 1
            end
        end
    )
end

return TitleState