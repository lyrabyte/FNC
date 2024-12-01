import "CoreLibs/graphics"
import "CoreLibs/timer"
import "CoreLibs/object"
import "../../funkin/music/bopper"
import "../mainmenu/mainmenustate"

local gfx <const> = playdate.graphics

class("TitleState").extends()

function TitleState:init(stateManager, conductor, musicPath, funkinMusic, funkinSounds, funkinImages, funkinFont, introTexts, skipIntro, SoundHandler, MusicHandler)
    TitleState.super.init(self)

    self.stateManager = stateManager
    self.conductor = conductor
    self.SoundHandler = SoundHandler
    self.musicHandler = MusicHandler

    self.funkinMusic = funkinMusic
    self.funkinSounds = funkinSounds
    self.funkinImages = funkinImages
    self.funkinFont = funkinFont

    self.crankinImage = gfx.image.new(funkinImages .. "crankin")
    assert(self.crankinImage, "Error: Could not load crankin image at path: " .. funkinImages .. "crankin")
    
    self.crankinVisible = false
    self.crankinX, self.crankinY = -5, -70
    self.crankinScale = 0.9
    self.inputEnabled = true

    assert(MusicHandler, "Error: MusicHandler must not be nil")

    self.canActivateCheatCode = false
    self.bopper = Bopper(conductor)

    gfx.setFont(funkinFont)

    self.funkinImage = gfx.image.new(funkinImages .. "funkin")
    assert(self.funkinImage, "Error: Could not load funkin image at path: " .. funkinImages .. "funkin")

    self.gfDanceTable = gfx.imagetable.new(funkinImages .. "title/gfDanceTitle")
    assert(self.gfDanceTable, "Error: Could not load gfDance imagetable at path: " .. funkinImages .. "title/gfDanceTitle")

    self.gfRingTone = "title/girlfriendsRingtone"
    self.mainMusic = "title/freakyMenu"

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
    self.shownText = {}
    self.currentRandomIntroText = nil
    self.musicHandler:playMusic(self.mainMusic)
    self.flashActive, self.canStart, self.flashTriggered = false, false, false
    self.fadeImage = gfx.image.new(400, 240, gfx.kColorWhite)
    self.fadeImageOpacity = 1.0
    self.startMessageOpacity, self.startMessageFadeOut = 1.0, true
    self.inputSequence = {}
    self.cheatCode = { 
        playdate.kButtonLeft, playdate.kButtonRight, playdate.kButtonLeft, playdate.kButtonRight, 
        playdate.kButtonUp, playdate.kButtonDown, playdate.kButtonUp, playdate.kButtonDown 
    }

    self.introTimers = {}
    table.insert(self.introTimers, playdate.timer.performAfterDelay(300, function() self:createCoolText({"Lyrabyte"}) end))
    table.insert(self.introTimers, playdate.timer.performAfterDelay(1475, function() self:addMoreText("presents") end))
    table.insert(self.introTimers, playdate.timer.performAfterDelay(2205, function() self:deleteCoolText() end))
    table.insert(self.introTimers, playdate.timer.performAfterDelay(2805, function() self:createCoolText({"A Port", "of"}) end))
    table.insert(self.introTimers, playdate.timer.performAfterDelay(3850, function() self:showImage() end))
    table.insert(self.introTimers, playdate.timer.performAfterDelay(4655, function()
        self:deleteCoolText()
        self:hideImage()
    end))
    table.insert(self.introTimers, playdate.timer.performAfterDelay(5130, function()
        self.currentRandomIntroText = self.introTexts[math.random(#self.introTexts)]
        if self.currentRandomIntroText then
            self:addMoreText(self.currentRandomIntroText[1] or "")
        end
    end))
    table.insert(self.introTimers, playdate.timer.performAfterDelay(6300, function()
        if self.currentRandomIntroText then
            self:addMoreText(self.currentRandomIntroText[2] or "")
            self.currentRandomIntroText = nil
        end
    end))
    table.insert(self.introTimers, playdate.timer.performAfterDelay(6900, function()
        self:deleteCoolText()
    end))
    table.insert(self.introTimers, playdate.timer.performAfterDelay(7475, function()
        self:addMoreText("Friday")
    end))
    table.insert(self.introTimers, playdate.timer.performAfterDelay(8075, function()
        self:addMoreText("Night")
    end))
    table.insert(self.introTimers, playdate.timer.performAfterDelay(8675, function()
        self:addMoreText("Crankin'")
    end))
    table.insert(self.introTimers, playdate.timer.performAfterDelay(9275, function()
        self:skipIntro()
    end))
end

function TitleState:onEnter()
    self.inputEnabled = true
    self.musicHandler:continuous()
    if self.currentCheatMusic == "gfRingTone" then
        self:setGfAnimationSpeed(0.005)
        self.bopper:setBopFrequencyMultiplier(2)
        self.musicHandler:playMusic(self.gfRingTone)
    else
        self.currentCheatMusic = "freakyMenu"
        self:setGfAnimationSpeed(0.0215)
        self.bopper:setBopFrequencyMultiplier(4 / 3) 
        self.musicHandler:playMusic(self.mainMusic)
    end
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
    gfx.setFont(self.funkinFont)

    if self.inputEnabled then
        self:checkCheatCode()

        if playdate.buttonJustPressed(playdate.kButtonA) then
            if self.canStart and not self.transitionTriggered then
                self.transitionTriggered = true
                self:handleStartAction()
            else
                self:skipIntro()
            end
            return
        end
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

    if self.canStart then
        self:drawStartMessage()
    end

    self.bopper:update()

    if self.showingImage and self.funkinImage then
        local adjustedScale = self.imageScale
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        self.funkinImage:drawScaled(self.imageX, self.imageY, adjustedScale)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    end

    if self.crankinVisible and self.crankinImage then
        local bump = self.bopper:getBumpValue()
        local adjustedScale = self.crankinScale + bump
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        self.crankinImage:drawScaled(self.crankinX, self.crankinY, adjustedScale)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    end    

    if self.showGif and self.gfDanceTable then
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        local frame = self.gfDanceTable:getImage(self.gfCurrentFrame)
        gfx.pushContext()
        gfx.setDrawOffset(0, 0)

        local scaledWidth = math.floor(frame.width * self.gfScale + 0.5)
        local scaledHeight = math.floor(frame.height * self.gfScale + 0.5)
        local drawX = self.gfX - scaledWidth // 2
        local drawY = self.gfY - scaledHeight // 2

        frame:drawScaled(drawX, drawY, self.gfScale)
        gfx.popContext()
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
    self.inputEnabled = false
    self.flashTriggered = false
    self:startWhiteFlash()

    if self.SoundHandler then
        self.SoundHandler:playConfirm()
    end

    playdate.timer.new(500, function()
        self.startMessageOpacity = 0
    end)

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
    self.flashTriggered = false
    self:startWhiteFlash()

    if self.SoundHandler then
        self.SoundHandler:playConfirm()
    end

    if self.currentCheatMusic == "gfRingTone" then
        self.currentCheatMusic = "freakyMenu"
        self.musicHandler:stopMusic()
        self:setGfAnimationSpeed(0.0215)
        self.bopper:setBopFrequencyMultiplier(4 / 3) 

        self.musicHandler:playMusic(self.mainMusic)
    else
        self.musicHandler:stopMusic()
        self.currentCheatMusic = "gfRingTone"
        self:setGfAnimationSpeed(0.005)
        self.bopper:setBopFrequencyMultiplier(2)

        self.musicHandler:playMusic(self.gfRingTone)
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
    self.bopper:setBopFrequencyMultiplier(4 / 3) 
    self:deleteCoolText()
    self:hideImage()
    self:startWhiteFlash()
    self.canActivateCheatCode = true
    self.showGif = true
    self.canStart = true
    self.inputEnabled = true
    self.transitionTriggered = false
    self:restartGfAnimationTimer()

    self.crankinVisible = true

    if self.introTimers then
        for _, timer in ipairs(self.introTimers) do
            if timer and timer.timeLeft > 0 then
                timer:remove()
            end
        end
        self.introTimers = nil
    end
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

return TitleState