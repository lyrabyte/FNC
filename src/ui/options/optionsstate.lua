import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/object"
import "../../funkin/core/wipeTransition"  

local gfx <const> = playdate.graphics

class("OptionsState").extends(gfx.sprite)

function OptionsState:init(funkinWeekFnt, funkinImages, mainMenuState, titleState, stateManager, SoundHandler)
    OptionsState.super.init(self)

    self.stateManager = stateManager
    self.mainMenuState = mainMenuState
    self.titleState = titleState
    self.SoundHandler = SoundHandler
    self.funkinImages = funkinImages
    self.funkinWeekFnt = funkinWeekFnt

    self.menuBGInv = gfx.image.new(self.funkinImages .. "mainmenu/menuBGInv")
    if not self.menuBGInv then
        error("Failed to load menuBGInv image!")
    end

    self.zoomFactor = 1.3
    self.scaledBG = self:scaleImageToFit(self.menuBGInv, 400 * self.zoomFactor, 240 * self.zoomFactor)

    self.scaledBGWidth, self.scaledBGHeight = self.scaledBG:getSize()

    self.backgroundOffsetY = 0
    self.targetBackgroundOffsetY = 0
    self.parallaxSpeed = 0.1
    self.shiftPerSelection = 10

    self.minBackgroundOffsetY = 150 - self.scaledBGHeight
    self.maxBackgroundOffsetY = 0

    self.menuOptions = {"Preferences", "Controls", "Input Offsets", "Exit"}
    self.lineSpacing = 50
    self.selectedIndex = 1
    self.animationSpeed = 0.2
    self.maxScale = 1.6 
    self.defaultScale = 1.3 
    self.scales = {}
    self.yPositions = {}

    self:initializeMenuPositions()

    self:add()
end

function OptionsState:onEnter()
    self.wipeTransition = WipeTransition(20, 400, 280)
end

function OptionsState:scaleImageToFit(image, targetWidth, targetHeight)
    local imgWidth, imgHeight = image:getSize()
    local scaleX = targetWidth / imgWidth
    local scaleY = targetHeight / imgHeight
    local scale = math.min(scaleX, scaleY)

    local scaledImage = gfx.image.new(targetWidth, targetHeight)
    gfx.pushContext(scaledImage)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    image:drawScaled(0, 0, scale)
    gfx.popContext()

    return scaledImage
end

function OptionsState:initializeMenuPositions()
    local centerY = 240 / 2
    for i = 1, #self.menuOptions do
        self.scales[i] = self.defaultScale
        self.yPositions[i] = centerY + ((i - (self.selectedIndex + 0.5)) * self.lineSpacing)
    end
end

function OptionsState:update()
    gfx.clear(gfx.kColorBlack)

    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    local bgX = (400 - self.scaledBGWidth) / 2
    local bgY = (240 - self.scaledBGHeight) / 2 + self.backgroundOffsetY
    self.scaledBG:draw(bgX, bgY)

    self.wipeTransition:update()

    if not self.wipeTransition:isCompleted() then
        return
    end

    if self.flashingOption then
        self.flashingOption()
    end

    self:updateParallax()
    self:animateOptions()
    self:drawMenu()
    self:handleInput()
end

function OptionsState:updateParallax()
    self.backgroundOffsetY = self.backgroundOffsetY + (self.targetBackgroundOffsetY - self.backgroundOffsetY) * self.parallaxSpeed

    if self.backgroundOffsetY > self.maxBackgroundOffsetY then
        self.backgroundOffsetY = self.maxBackgroundOffsetY
    elseif self.backgroundOffsetY < self.minBackgroundOffsetY then
        self.backgroundOffsetY = self.minBackgroundOffsetY
    end
end

function OptionsState:updateTargetBackgroundOffset()
    self.targetBackgroundOffsetY = - (self.selectedIndex - 1) * self.shiftPerSelection

    if self.targetBackgroundOffsetY < self.minBackgroundOffsetY then
        self.targetBackgroundOffsetY = self.minBackgroundOffsetY
    elseif self.targetBackgroundOffsetY > self.maxBackgroundOffsetY then
        self.targetBackgroundOffsetY = self.maxBackgroundOffsetY
    end
end

function OptionsState:animateOptions()
    local centerY = 240 / 2
    for i = 1, #self.menuOptions do
        if i == self.selectedIndex then
            self.scales[i] = self.scales[i] + (self.maxScale - self.scales[i]) * self.animationSpeed
        else
            self.scales[i] = self.scales[i] + (self.defaultScale - self.scales[i]) * self.animationSpeed
        end

        local targetY = centerY + ((i - (self.selectedIndex + 0.5)) * self.lineSpacing)
        self.yPositions[i] = self.yPositions[i] + (targetY - self.yPositions[i]) * self.animationSpeed
    end
end

function OptionsState:drawMenu()
    local screenWidth = 400
    local centerX = screenWidth / 2

    gfx.setFont(self.funkinWeekFnt)
    for i, option in ipairs(self.menuOptions) do
        if i == self.selectedIndex and self.flashingOption and not self.isOptionVisible then

            goto continue
        end

        local scale = self.scales[i]
        local yPosition = self.yPositions[i]
        local text = option
        local textWidth, textHeight = gfx.getTextSize(text)
        local x = centerX - (textWidth * scale) / 2

        gfx.pushContext()
        local textImage = gfx.image.new(textWidth * scale, textHeight * scale)
        gfx.lockFocus(textImage)
        gfx.drawText(text, 0, 0)
        gfx.unlockFocus()
        textImage:drawScaled(x, yPosition, scale)
        gfx.popContext()

        ::continue::
    end

    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function OptionsState:handleInput()

    if playdate.buttonJustPressed(playdate.kButtonUp) then
        self:changeSelection(-1)
    elseif playdate.buttonJustPressed(playdate.kButtonDown) then
        self:changeSelection(1)
    elseif playdate.buttonJustPressed(playdate.kButtonA) then
        self:confirmSelection()
    elseif playdate.buttonJustPressed(playdate.kButtonB) then
        self:startTransitionToMainMenu()
    end

    local crankChange = playdate.getCrankChange()

    local sensitivityThreshold = 45 
    self.crankBuffer = (self.crankBuffer or 0) + crankChange

    if math.abs(self.crankBuffer) >= sensitivityThreshold then
        local steps = math.floor(self.crankBuffer / sensitivityThreshold)
        self:changeSelection(steps)
        self.crankBuffer = self.crankBuffer % sensitivityThreshold 
    end
end

function OptionsState:changeSelection(direction)
    self.selectedIndex = self.selectedIndex + direction
    if self.selectedIndex < 1 then
        self.selectedIndex = #self.menuOptions
    elseif self.selectedIndex > #self.menuOptions then
        self.selectedIndex = 1
    end
    if self.SoundHandler then
        self.SoundHandler:playScroll()
    end
    self:updateTargetBackgroundOffset()
end

function OptionsState:confirmSelection()
    local selectedOption = self.menuOptions[self.selectedIndex]

    if self.SoundHandler then
        self.SoundHandler:playConfirm()
    else
        print("Error: SoundHandler is not initialized.")
    end

    local flashDuration = 0.8 
    local flashInterval = 0.05 
    local flashEndTime = playdate.getCurrentTimeMilliseconds() + (flashDuration * 1000)
    local isFlashing = true
    local lastFlashToggleTime = 0

    self.flashingOption = function()
        local currentTime = playdate.getCurrentTimeMilliseconds()

        if currentTime > flashEndTime then

            isFlashing = false
            self.flashingOption = nil

            if selectedOption == "Preferences" then
                print("Navigate to Sound Options")
            elseif selectedOption == "Controls" then
                self.stateManager:switchTo("controls")
            elseif selectedOption == "Input Offsets" then
                print("Navigate to Display Options")
            elseif selectedOption == "Exit" then
                self:startTransitionToMainMenu()
            end

            return
        end

        if currentTime - lastFlashToggleTime >= (flashInterval * 1000) then
            self.isOptionVisible = not self.isOptionVisible
            lastFlashToggleTime = currentTime
        end
    end
end

function OptionsState:startTransitionToMainMenu()
    self.stateManager:switchTo("mainMenu")
end

return OptionsState