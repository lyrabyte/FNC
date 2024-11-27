import "CoreLibs/graphics"
import "CoreLibs/timer"
import "CoreLibs/object"
import "../../funkin/music/bopper"
import "../mainmenu/mainmenustate"

local gfx <const> = playdate.graphics

class("TitleState").extends()

function TitleState:init(stateManager, conductor, audioPlayer, funkinMusic, funkinSounds, funkinImages, funkinFont, introTexts, skipIntro)
    TitleState.super.init(self)

    self.stateManager = stateManager
    self.conductor = conductor
    
    assert(audioPlayer, "Error: audioPlayer must not be nil")
    self.introMusic = audioPlayer
    assert(self.introMusic, "Error: introMusic could not be initialized")

    self.canActivateCheatCode = false
    self.bopper = Bopper(conductor)

    gfx.setFont(funkinFont)
    
    self.funkinImage = gfx.image.new(funkinImages .. "funkin")
    assert(self.funkinImage, "Error: Could not load funkin image at path: " .. funkinImages .. "funkin")
    
    self.gfDanceTable = gfx.imagetable.new(funkinImages .. "title/gfDanceTitle")
    assert(self.gfDanceTable, "Error: Could not load gfDance imagetable at path: " .. funkinImages .. "title/gfDanceTitle")
    
    assert(funkinMusic .. "title/girlfriendsRingtone" and (funkinMusic .. "title/girlfriendsRingtone") ~= "", "Error: girlfriendsRingtone must be a valid path")
    self.gfRingTone = funkinMusic .. "title/girlfriendsRingtone"
    
    assert(funkinSounds .. "menus/Confirm" and (funkinSounds .. "menus/Confirm") ~= "", "Error: confirm must be a valid path")
    self.confirm = funkinSounds .. "menus/Confirm"
    
    self.gfScale, self.gfX, self.gfY = 0.28, 305, 180
    self.gfCurrentFrame, self.gfAnimationSpeed = 1, 0.0215
    self:initializeGfAnimation()
    
    self.showingImage, self.showGif = false, false
    self.imageX, self.imageY, self.imageScale = 97, 118, 1.0
    
    self.introTexts = self:readIntroTexts(introTexts)
    assert(#self.introTexts > 0, "Error: Intro texts file is empty or could not be read")
    self.currentRandomIntroText = nil
    
    if not skipIntro then
        self:setupIntroSequence()
    else
        self:skipIntro()
    end
end

function TitleState:initializeGfAnimation()
    self.gfAnimationTimer = playdate.timer.keyRepeatTimerWithDelay(
        self.gfAnimationSpeed * 1000,
        self.gfAnimationSpeed * 1000,
        function()
            self.gfCurrentFrame = (self.gfCurrentFrame % self.gfDanceTable:getLength()) + 1
        end
    )
end

function TitleState:setupIntroSequence()
    self.textLines = {
        {beat = 1.0, action = function() self:createCoolText({"Lyrabyte"}) end},
        {beat = 2.4, action = function() self:addMoreText("presents") end},
        {beat = 3.3, action = self.deleteCoolText},
        {beat = 4.01, action = function() self:createCoolText({"A Port", "of"}) end},
        {beat = 5.6, action = self.showImage},
        {beat = 6.4, action = function()
            self:deleteCoolText()
            self:hideImage()
        end},
        {beat = 7.31, action = function()
            self.currentRandomIntroText = self.introTexts[math.random(#self.introTexts)]
            if self.currentRandomIntroText then
                self:addMoreText(self.currentRandomIntroText[1] or "")
            end
        end},
        {beat = 8.98, action = function()
            if self.currentRandomIntroText then
                self:addMoreText(self.currentRandomIntroText[2] or "")
                self.currentRandomIntroText = nil
            end
        end},
        {beat = 9.55, action = self.deleteCoolText},
        {beat = 10.35, action = function() self:addMoreText("Friday") end},
        {beat = 11.25, action = function() self:addMoreText("Night") end},
        {beat = 12.07, action = function() self:addMoreText("Crankin'") end},
        {beat = 13, action = self.skipIntro},
    }

    table.sort(self.textLines, function(a, b) return a.beat < b.beat end)

    self.nextBeatIndex = 1
    self.shownText = {}

    self.introMusic:play()
    self.bopper:setBopFrequencyMultiplier(0.02)

    self.flashActive, self.canStart, self.flashTriggered = false, false, false

    self.fadeImage = gfx.image.new(400, 240, gfx.kColorWhite)
    self.fadeImageOpacity = 1.0

    self.startMessageOpacity, self.startMessageFadeOut = 1.0, true

    self.inputSequence = {}
    self.cheatCode = { 
        playdate.kButtonLeft, playdate.kButtonRight, playdate.kButtonLeft, playdate.kButtonRight, 
        playdate.kButtonUp, playdate.kButtonDown, playdate.kButtonUp, playdate.kButtonDown 
    }
end

function TitleState:readIntroTexts(path)
    local texts, file = {}, playdate.file.open(path, playdate.file.kFileRead)
    if file then
        local line = file:readline()
        while line do
            line = line:match("^%s*(.-)%s*$")
            if line and #line > 0 then
                local splitLines = {}
                for part in line:gmatch("[^%-%-]+") do
                    local trimmed = part:match("^%s*(.-)%s*$")
                    table.insert(splitLines, trimmed)
                end
                table.insert(texts, splitLines)
            end
            line = file:readline()
        end
        file:close()
    end
    return texts
end

function TitleState:update()
    gfx.clear(gfx.kColorBlack)
    gfx.setFont(funkinFont)
    self:checkCheatCode()

    self.introMusic:setFinishCallback(function() self.introMusic:play() end)

    if playdate.buttonJustPressed(playdate.kButtonA) then
        if self.canStart and not self.transitionTriggered then
            self.transitionTriggered = true
            self:playSound(self.confirm)
            self:handleStartAction()
        else
            self:skipIntro()
        end
        return
    end

    local elapsedTime = playdate.getCurrentTimeMilliseconds()
    local beatDurationMs = self.conductor.stepLengthMs * 4
    local currentBeat = self.conductor.globalStep / 4 + (elapsedTime - self.conductor.lastStepTime) / beatDurationMs

    while self.nextBeatIndex <= #self.textLines and currentBeat >= self.textLines[self.nextBeatIndex].beat do
        self.bopper:setBopFrequencyMultiplier(0.4)
        self.textLines[self.nextBeatIndex].action(self)
        self.nextBeatIndex += 1
    end

    gfx.setFont(gfx.getFont())
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)

    local y = 80
    for _, line in ipairs(self.shownText) do
        if type(line.text) == "string" then
            gfx.drawTextAligned(line.text, 200, y, kTextAlignment.center)
            y += 20
        end
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
        local scaledWidth, scaledHeight = frame.width * self.gfScale, frame.height * self.gfScale
        frame:drawScaled(self.gfX - scaledWidth / 2, self.gfY - scaledHeight / 2, self.gfScale)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    end

    if self.flashActive then
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        self.fadeImage:drawFaded(0, 0, self.fadeImageOpacity, gfx.image.kDitherTypeBayer8x8)
        self.fadeImageOpacity = math.max(self.fadeImageOpacity - 0.05, 0)
        if self.fadeImageOpacity == 0 then
            self.flashActive = false
        end
    end
end

function TitleState:handleStartAction()
    self.flashTriggered = false
    self:startWhiteFlash()

    playdate.timer.new(500, function()
        self.startMessageOpacity = 0
    end)

    self:playSound(self.confirm)

    local function waitForFlash()
        if not self.flashActive then
            self.stateManager:switchTo("mainMenu")
        else
            playdate.timer.performAfterDelay(100, waitForFlash)
        end
    end

    waitForFlash()
end

function TitleState:checkCheatCode()
    if not self.canActivateCheatCode then return end

    local button
    if playdate.buttonJustPressed(playdate.kButtonLeft) then
        button = playdate.kButtonLeft
    elseif playdate.buttonJustPressed(playdate.kButtonRight) then
        button = playdate.kButtonRight
    elseif playdate.buttonJustPressed(playdate.kButtonUp) then
        button = playdate.kButtonUp
    elseif playdate.buttonJustPressed(playdate.kButtonDown) then
        button = playdate.kButtonDown
    end

    if button then
        table.insert(self.inputSequence, button)
        if #self.inputSequence > #self.cheatCode then
            table.remove(self.inputSequence, 1)
        end

        if #self.inputSequence == #self.cheatCode then
            local match = true
            for i, btn in ipairs(self.cheatCode) do
                if self.inputSequence[i] ~= btn then
                    match = false
                    break
                end
            end
            if match then
                self:activateCheatCode()
                self.inputSequence = {}
            end
        end
    end
end

function TitleState:activateCheatCode()
    self.canActivateCheatCode = false
    self.flashTriggered = false
    self:startWhiteFlash()
    self:setGfAnimationSpeed(0.005)
    self.bopper:setBopFrequencyMultiplier(2)
    self.introMusic:stop()

    self:playSound(self.confirm)

    if self.gfRingTone ~= "" then
        self.introMusic = playdate.sound.fileplayer.new(self.gfRingTone)
        self.introMusic:setVolume(0)
        self.introMusic:play()

        self.fadeTimer = playdate.timer.new(100, function()
            local currentVolume = self.introMusic:getVolume()
            if currentVolume < 1 then
                self.introMusic:setVolume(math.min(currentVolume + 0.1, 1))
            else
                self.fadeTimer:remove()
            end
        end)
        self.fadeTimer.repeats = true
    end
end

function TitleState:setGfAnimationSpeed(speed)
    self.gfAnimationSpeed = speed
    if self.gfAnimationTimer then
        self.gfAnimationTimer:remove()
    end
    self.gfAnimationTimer = playdate.timer.keyRepeatTimerWithDelay(
        self.gfAnimationSpeed * 1000,
        self.gfAnimationSpeed * 1000,
        function()
            self.gfCurrentFrame = (self.gfCurrentFrame % self.gfDanceTable:getLength()) + 1
        end
    )
end

function TitleState:drawStartMessage()
    if self.startMessageFadeOut then
        self.startMessageOpacity = math.max(self.startMessageOpacity - 0.05, 0)
        if self.startMessageOpacity == 0 then
            self.startMessageFadeOut = false
        end
    else
        self.startMessageOpacity = math.min(self.startMessageOpacity + 0.05, 1)
        if self.startMessageOpacity == 1 then
            self.startMessageFadeOut = true
        end
    end

    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.setDitherPattern(self.startMessageOpacity, gfx.image.kDitherTypeBayer8x8)
    self:drawScaledText("Press 'A' To Start", 100, 220, 0.8)
end

function TitleState:drawScaledText(text, x, y, scale)
    local font = gfx.getFont()
    local textWidth, textHeight = font:getTextWidth(text), font:getHeight()

    local textImage = gfx.image.new(textWidth, textHeight)
    gfx.pushContext(textImage)
    gfx.clear(gfx.kColorClear)
    gfx.drawText(text, 0, 0)
    gfx.popContext()

    local scaledImage = textImage:scaledImage(scale)
    scaledImage:draw(x - scaledImage.width / 2, y - scaledImage.height / 2)
end

function TitleState:createCoolText(lines)
    for _, line in ipairs(lines) do
        table.insert(self.shownText, { text = line })
    end
end

function TitleState:addMoreText(line)
    if type(line) == "string" then
        table.insert(self.shownText, { text = line })
    elseif type(line) == "table" then
        for _, subLine in ipairs(line) do
            table.insert(self.shownText, { text = subLine })
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
    self.imageX, self.imageY = 0, 0
    self.showingImage = true
    self:startWhiteFlash()
    self.showGif = true
    self.canActivateCheatCode = true
    self.canStart = true
    self.transitionTriggered = false
    self:restartGfAnimationTimer()
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
    self:initializeGfAnimation()
end

function TitleState:playSound(soundPath)
    local sound = playdate.sound.fileplayer.new(soundPath)
    if sound then
        sound:setVolume(1.3)
        sound:play()
    end
end

return TitleState
