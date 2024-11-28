import "CoreLibs/graphics"
import "../title/titleState"
import "../freeplay/freeplaystate"

local gfx <const> = playdate.graphics

class("MainMenuState").extends()

function MainMenuState:init(introMusic, funkinMusic, funkinSounds, funkinImages, titleScreen, stateManager)
    MainMenuState.super.init(self)

    self.stateManager = stateManager
    self.titleScreen = titleScreen 
    self.freeplayState = FreeplayState(self) 

    self.funkinMusic = funkinMusic
    self.funkinSounds = funkinSounds
    self.funkinImages = funkinImages

    self.scrollSoundPath = self.funkinSounds .. "menus/scroll"
    self.confirmSoundPath = self.funkinSounds .. "menus/confirm"
    self.wipeHeight = 0
    self.wipeSpeed = 20
    self.gradientHeight = 20
    self.wipeCompleted = false

    self.mainMenuBG = gfx.image.new(self.funkinImages .. "mainmenu/menuBG")
    if not self.mainMenuBG then
        error("Failed to load mainMenuBG image!")
    end

    self.scaledBG = self:scaleImageToFit(self.mainMenuBG, 400, 240)

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

    self.scrollSound = playdate.sound.sampleplayer.new(self.scrollSoundPath)
    if not self.scrollSound then
        print("Error: Failed to load scroll sound.")
    end

    self.confirmSound = playdate.sound.sampleplayer.new(self.confirmSoundPath)
    if not self.confirmSound then
        print("Error: Failed to load confirm sound.")
    end

    self.isFlashing = false
    self.flashState = false
    self.flashTimer = nil
end


function MainMenuState:settitleScreen(titleScreen)
    self.titleScreen = titleScreen
    
    self.confirmSound = playdate.sound.fileplayer.new(self.titleScreen.confirm)
    if not self.confirmSound then
        print("Error: Failed to load confirm sound.")
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

function MainMenuState:resetWipe()
    self.wipeHeight = 0
    self.wipeCompleted = false
end

function MainMenuState:update()
    local gfx = playdate.graphics
    gfx.clear(gfx.kColorBlack)

    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    self.scaledBG:draw(0, 0)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    
    if self.titleScreen.introMusic and not self.titleScreen.introMusic:isPlaying() then
        self.titleScreen.introMusic:play()
    elseif not self.titleScreen.introMusic then
        print("Error: introMusic is not set in titleScreen.")
    end

    if not self.wipeCompleted then
        self:performWipe()
    else
        self:animateOptions()
        self:drawMenu()
        self:handleInput()
    end
end

function MainMenuState:performWipe()
    for i = 0, self.wipeHeight - 1 do
        local alpha = 1 - (i / self.wipeHeight)
        gfx.setDitherPattern(alpha, gfx.image.kDitherTypeBayer4x4)
        gfx.fillRect(0, i, 400, 1)
    end

    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, self.wipeHeight, 400, 240 - self.wipeHeight)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    self.wipeHeight = self.wipeHeight + self.wipeSpeed

    if self.wipeHeight >= 350 then
        self.wipeHeight = 350
        self.wipeCompleted = true
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

    
    if self.scrollSound then
        self.scrollSound:play()
    else
        print("Error: Scroll sound is not set or is invalid.")
    end
end

function MainMenuState:handleInput()
    
    local crankChange = playdate.getCrankChange()
    self.crankThreshold = self.crankThreshold or 20 

    
    self.crankAccumulator = (self.crankAccumulator or 0) + crankChange

    
    if math.abs(self.crankAccumulator) >= self.crankThreshold then
        if self.crankAccumulator > 0 then
            self:changeSelection(1)
        else
            self:changeSelection(-1)
        end
        
        self.crankAccumulator = 0
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
    if self.confirmSound then
        self.confirmSound:setVolume(1.3)
        self.confirmSound:play()
    else
        print("Error: Confirm sound is not set or is invalid.")
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
    
    self.wipeCompleted = false

    
    if self.scrollSound then
        self.scrollSound:play()
    end

    
    self.titleScreen:skipIntro()

    self.stateManager:switchTo("title")

    self.titleScreen.onExit = function()
        self:resetWipe()
    end
end

return MainMenuState
