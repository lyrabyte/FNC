import "CoreLibs/graphics"
import "../title/titleState"
import "../freeplay/freeplaystate"
import "../../funkin/core/wipeTransition"  
import "../../funkin/core/SoundHandler"  

local gfx <const> = playdate.graphics

class("MainMenuState").extends()

function MainMenuState:init(funkinMusic, funkinSounds, funkinImages, titleScreen, stateManager, SoundHandler, MusicHandler)
    MainMenuState.super.init(self)

    self.stateManager = stateManager
    self.titleScreen = titleScreen
    self.musicHandler = MusicHandler
    self.freeplayState = FreeplayState(self) 
    self.SoundHandler = SoundHandler
    self.funkinMusic = funkinMusic
    self.funkinSounds = funkinSounds
    self.funkinImages = funkinImages
    self.isConfirming = false
    self.gradientHeight = 20

    self.mainMenuBG = gfx.image.new(self.funkinImages .. "mainmenu/menuBG")
    if not self.mainMenuBG then
        error("Failed to load mainMenuBG image!")
    end

    self.zoomFactor = 1.3
    self.scaledBG = self:scaleImageToFit(self.mainMenuBG, 400 * self.zoomFactor, 240 * self.zoomFactor)

    self.scaledBGWidth, self.scaledBGHeight = self.scaledBG:getSize()

    self.backgroundOffsetY = 0
    self.targetBackgroundOffsetY = 0
    self.parallaxSpeed = 0.1
    self.shiftPerSelection = 10

    self.minBackgroundOffsetY = 150 - self.scaledBGHeight
    self.maxBackgroundOffsetY = 0

    self.menuOptions = {
        {name = "StoryMode", image0 = nil, image1 = nil, scale = 0.5, xModifier = 0, yModifier = 0, targetScale = 0.5, yPosition = 0},
        {name = "Freeplay", image0 = nil, image1 = nil, scale = 0.5, xModifier = 0, yModifier = 0, targetScale = 0.5, yPosition = 0},
        {name = "Options", image0 = nil, image1 = nil, scale = 0.5, xModifier = 0, yModifier = 0, targetScale = 0.5, yPosition = 0},
        {name = "Credits", image0 = nil, image1 = nil, scale = 0.5, xModifier = 0, yModifier = 0, targetScale = 0.5, yPosition = 0}
    }

    self.lineSpacing = 60
    self.selectedIndex = 1
    self.animationSpeed = 0.2
    self.maxScale = 1.05
    self.defaultScale = 0.6

    for _, option in ipairs(self.menuOptions) do
        option.image0 = gfx.image.new(self.funkinImages .. "mainmenu/" .. option.name .. "0")
        option.image1 = gfx.image.new(self.funkinImages .. "mainmenu/" .. option.name .. "1")

        if not option.image0 or not option.image1 then
            error("Failed to load images for " .. option.name)
        end

        option.yPosition = 0
    end

    self.isFlashing = false
    self.flashState = false
    self.flashTimer = nil

    self:initializeMenuPositions()

    self:updateTargetBackgroundOffset()
end

function MainMenuState:onEnter()
    self.isConfirming = false
    self.wipeTransition = WipeTransition(8, 400, 280)

end

function MainMenuState:initializeMenuPositions()
    local centerY = 240 / 2
    for i, option in ipairs(self.menuOptions) do
        local targetY = centerY + ((i - (self.selectedIndex + 0.5)) * self.lineSpacing)
        option.yPosition = targetY
    end
end

function MainMenuState:settitleScreen(titleScreen)
    self.titleScreen = titleScreen
    if self.SoundHandler then
        self.SoundHandler:playConfirm()
    else
        print("Error: SoundHandler is not initialized.")
    end
end

function MainMenuState:scaleImageToFit(image, targetWidth, targetHeight)
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

function MainMenuState:update()
    local gfx = playdate.graphics
    gfx.clear(gfx.kColorBlack)

    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    local bgX = (400 - self.scaledBGWidth) / 2
    local bgY = (240 - self.scaledBGHeight) / 2 + self.backgroundOffsetY
    self.scaledBG:draw(bgX, bgY)

    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)

    self.wipeTransition:update()

    if not self.wipeTransition:isCompleted() then
        self.wipeTransition:performWipe()
    else
        self:animateOptions()
        self:updateParallax()
        self:drawMenu()
        self:handleInput()
    end
end

function MainMenuState:animateOptions()
    local centerY = 240 / 2
    for i, option in ipairs(self.menuOptions) do
        if i == self.selectedIndex then
            option.targetScale = self.maxScale
        else
            option.targetScale = self.defaultScale
        end

        option.scale = option.scale + (option.targetScale - option.scale) * self.animationSpeed

        local targetY = centerY + ((i - (self.selectedIndex + 0.5)) * self.lineSpacing) + option.yModifier

        option.yPosition = option.yPosition + (targetY - option.yPosition) * self.animationSpeed
    end
end

function MainMenuState:updateParallax()
    self.backgroundOffsetY = self.backgroundOffsetY + (self.targetBackgroundOffsetY - self.backgroundOffsetY) * self.parallaxSpeed

    if self.backgroundOffsetY > self.maxBackgroundOffsetY then
        self.backgroundOffsetY = self.maxBackgroundOffsetY
    elseif self.backgroundOffsetY < self.minBackgroundOffsetY then
        self.backgroundOffsetY = self.minBackgroundOffsetY
    end
end

function MainMenuState:drawMenu()
    local screenWidth, screenHeight = 400, 240
    local centerX = screenWidth / 2

    for i, option in ipairs(self.menuOptions) do
        if i ~= self.selectedIndex then
            self:drawOption(option, centerX, i)
        end
    end

    self:drawOption(self.menuOptions[self.selectedIndex], centerX, self.selectedIndex)
end

function MainMenuState:drawOption(option, centerX, index)
    local image = option.image0
    if index == self.selectedIndex then
        if self.isFlashing then
            image = self.flashState and option.image1 or option.image0
        else
            image = option.image1
        end
    else
        image = option.image0
    end

    local scale = option.scale
    local imgWidth, imgHeight = image:getSize()
    local scaledWidth = imgWidth * scale
    local scaledHeight = imgHeight * scale

    local x = centerX - (scaledWidth / 2) + option.xModifier
    local y = option.yPosition 

    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    image:drawScaled(x, y, scale)
end

function MainMenuState:changeSelection(direction)
    if self.isConfirming then
        return
    end

    if self.isFlashing then
        self.isFlashing = false
        self.flashState = false
        if self.flashTimer then
            self.flashTimer:remove()
            self.flashTimer = nil
        end
    end

    self.selectedIndex = self.selectedIndex + direction
    if self.selectedIndex < 1 then
        self.selectedIndex = #self.menuOptions
    elseif self.selectedIndex > #self.menuOptions then
        self.selectedIndex = 1
    end

    self:updateTargetBackgroundOffset()

    if self.SoundHandler then
        self.SoundHandler:playScroll()
    else
        print("Error: SoundHandler is not initialized.")
    end
end

function MainMenuState:updateTargetBackgroundOffset()
    self.targetBackgroundOffsetY = - (self.selectedIndex - 1) * self.shiftPerSelection

    if self.targetBackgroundOffsetY < self.minBackgroundOffsetY then
        self.targetBackgroundOffsetY = self.minBackgroundOffsetY
    elseif self.targetBackgroundOffsetY > self.maxBackgroundOffsetY then
        self.targetBackgroundOffsetY = self.maxBackgroundOffsetY
    end
end

function MainMenuState:handleInput()
    if self.isConfirming then
        return
    end

    local crankChange = playdate.getCrankChange()
    self.crankThreshold = self.crankThreshold or 45
    self.crankAccumulator = (self.crankAccumulator or 0) + crankChange

    if math.abs(self.crankAccumulator) >= self.crankThreshold then
        if self.crankAccumulator > 0 then
            self:changeSelection(1)
        else
            self:changeSelection(-1)
        end

        self.crankAccumulator = self.crankAccumulator % self.crankThreshold
    end

    if playdate.buttonJustPressed(playdate.kButtonUp) then
        self:changeSelection(-1)
    elseif playdate.buttonJustPressed(playdate.kButtonDown) then
        self:changeSelection(1)
    elseif playdate.buttonJustPressed(playdate.kButtonB) then
        self:transitionTotitleScreen()
    elseif playdate.buttonJustPressed(playdate.kButtonA) then
        self:confirmSelection()
    end
end

function MainMenuState:confirmSelection()
    if self.isConfirming then
        return
    end

    self.isConfirming = true

    if self.SoundHandler then
        self.SoundHandler:playConfirm()
    else
        print("Error: SoundHandler is not initialized.")
    end

    if not self.isFlashing then
        self.isFlashing = true
        self.flashState = true

        self.flashTimer = playdate.timer.new(100, function()
            if not self.isFlashing then
                return
            end
            self.flashState = not self.flashState
        end)
        self.flashTimer.repeats = true

        playdate.timer.performAfterDelay(1250, function()
            self.isFlashing = false
            if self.flashTimer then
                self.flashTimer:remove()
                self.flashTimer = nil
            end
            self.flashState = false

            local selectedOption = self.menuOptions[self.selectedIndex].name
            if selectedOption == "Freeplay" then
                self.stateManager:switchTo("freeplay")
            elseif selectedOption == "StoryMode" then
                self.stateManager:switchTo("story")
            elseif selectedOption == "Options" then
                self.stateManager:switchTo("options")
            elseif selectedOption == "Credits" then
                self.stateManager:switchTo("credits")
            else
                print("Option Selected: " .. selectedOption)
            end
        end)
    end
end

function MainMenuState:transitionTotitleScreen()
    self.isConfirming = false
    self.wipeTransition:reset()

    self.titleScreen:skipIntro()

    self.stateManager:switchTo("title")

    self.titleScreen.onExit = function()
        self.wipeTransition:reset()
    end
end

return MainMenuState