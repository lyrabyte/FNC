import "CoreLibs/graphics"
import "../../funkin/core/wipeTransition"
import "../../funkin/libs/json"
import "../../funkin/core/SoundHandler"  

local gfx <const> = playdate.graphics

class("ControlsState").extends(gfx.sprite)

function ControlsState:init(funkinWeekFnt, funkinSounds, funkinImages, optionsState, controlsFilePath, stateManager, SoundHandler)
    ControlsState.super.init(self)

    self.stateManager = stateManager
    self.optionsState = optionsState
    self.funkinWeekFnt = funkinWeekFnt
    self.SoundHandler = SoundHandler
    self.funkinSounds = funkinSounds
    self.controlsFilePath = controlsFilePath
    self.headerYPosition = 20 
    self.headerTargetY = self.headerYPosition 

    self.controlMapping = {
        ["playdate.kButtonLeft"]  = "DPad-Left",
        ["playdate.kButtonRight"] = "DPad-Right",
        ["playdate.kButtonUp"]    = "DPad-Up",
        ["playdate.kButtonDown"]  = "DPad-Down",
        ["playdate.kButtonA"]     = "A Button",
        ["playdate.kButtonB"]     = "B Button"
    }

    self.menuBGInv = gfx.image.new(funkinImages .. "mainmenu/menuBGInv")
    if not self.menuBGInv then
        error("Failed to load menuBGInv image!")
    end

    self.zoomFactor = 1.3
    self.scaledBG = self:scaleImageToFit(self.menuBGInv, 400 * self.zoomFactor, 240 * self.zoomFactor)
    self.scaledBGWidth, self.scaledBGHeight = self.scaledBG:getSize()

    self.backgroundOffsetY = 0
    self.parallaxSpeed = 0.1

    self.wipeTransition = WipeTransition(20, 400, 240)
    self.wipeInProgress = true

    self.actions = { "Left", "Down", "Up", "Right" } 
    self.selectedIndex = 1
    self.lineSpacing = 50
    self.defaultScale = 1.0
    self.selectedScale = 1.5
    self.animationSpeed = 0.2
    self.scales = {}
    self.yPositions = {}

    self.isEditing = false 
    self:initMenuPositions()

    self.controls = self:loadControls()

    self:add()
end

function ControlsState:initMenuPositions()
    local centerY = 240 / 2
    for i = 1, #self.actions do
        self.scales[i] = self.defaultScale
        self.yPositions[i] = centerY + ((i - (self.selectedIndex + 0.5)) * self.lineSpacing)
    end
end

function ControlsState:loadControls()
    local file = playdate.file.open(self.controlsFilePath, playdate.file.kFileRead)
    if not file then
        error("Failed to load controls file!")
    end

    local fileContent = ""
    local chunkSize = 256
    while true do
        local chunk = file:read(chunkSize)
        if not chunk or #chunk == 0 then break end
        fileContent = fileContent .. chunk
    end
    file:close()

    local success, decodedData = pcall(json.decode, fileContent)
    if not success or not decodedData.controls then
        error("Failed to parse JSON controls data!")
    end

    for _, action in ipairs(self.actions) do
        if not decodedData.controls[action] then

            decodedData.controls[action] = "playdate.kButton" .. action
            print(string.format("Warning: '%s' action missing in JSON. Setting default to '%s'.", action, decodedData.controls[action]))
        end
    end

    return decodedData.controls
end

function ControlsState:saveControls()
    local file = playdate.file.open(self.controlsFilePath, playdate.file.kFileWrite)
    if not file then
        error("Failed to save controls file!")
    end

    local controlsData = { controls = self.controls }
    local success, jsonData = pcall(json.encode, controlsData)
    if not success then
        error("Failed to encode controls data!")
    end

    file:write(jsonData)
    file:close()
end

function ControlsState:scaleImageToFit(image, targetWidth, targetHeight)
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

function ControlsState:onEnter()
    self.wipeTransition:reset()
    self.wipeInProgress = true
end

function ControlsState:update()
    gfx.clear(gfx.kColorBlack)

    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    local bgX = (400 - self.scaledBGWidth) / 2
    local bgY = (240 - self.scaledBGHeight) / 2 + self.backgroundOffsetY
    self.scaledBG:draw(bgX, bgY)

    if self.wipeInProgress then
        self.wipeTransition:update()
        if self.wipeTransition:isCompleted() then
            self.wipeInProgress = false
        end
        return
    end

    self:animateMenu()
    self:animateHeader()
    self:drawHeader()
    self:drawControls()
    self:handleInput()
end

function ControlsState:animateMenu()
    local centerY = 240 / 2
    for i = 1, #self.actions do

        if i == self.selectedIndex then
            self.scales[i] = self.scales[i] + (self.selectedScale - self.scales[i]) * self.animationSpeed
        else
            self.scales[i] = self.scales[i] + (self.defaultScale - self.scales[i]) * self.animationSpeed
        end

        local targetY = centerY + ((i - (self.selectedIndex + 0.5)) * self.lineSpacing)
        self.yPositions[i] = self.yPositions[i] + (targetY - self.yPositions[i]) * self.animationSpeed
    end
end

function ControlsState:animateHeader()

    if self.isEditing then

        self.headerTargetY = 0
    else

        local headerOffset = (self.selectedIndex - 1) * 20 
        self.headerTargetY = 20 - headerOffset

        if self.selectedIndex > 2 then
            self.headerTargetY = -50
        elseif self.selectedIndex == 1 then
            self.headerTargetY = 20 
        end
    end

    self.headerYPosition = self.headerYPosition + (self.headerTargetY - self.headerYPosition) * self.animationSpeed
end

function ControlsState:drawHeader()
    local headerText = self.isEditing and "Press New Button" or "Notes"

    local drawPositionY = self.isEditing and 0 or self.headerYPosition

    if drawPositionY > -30 and drawPositionY < 240 then
        gfx.setFont(self.funkinWeekFnt)
        local textWidth, textHeight = gfx.getTextSize(headerText)
        gfx.drawText(headerText, (400 - textWidth) / 2, drawPositionY)
    end
end

function ControlsState:drawControls()
    if self.isEditing then

        local i = self.selectedIndex
        local action = self.actions[i]
        if not action then
            print("Error: action is nil in drawControls while editing!")
            return
        end
        local scale = self.scales[i]
        local y = self.yPositions[i]
        local controlKey = self.controls[action]
        local mappedControl = controlKey and self.controlMapping[controlKey] or "Unknown"
        local text = string.format("%s: %s", action, mappedControl)
        local textWidth, textHeight = gfx.getTextSize(text)

        gfx.pushContext()
        local textImage = gfx.image.new(textWidth * scale, textHeight * scale)
        gfx.lockFocus(textImage)
        gfx.drawText(text, 0, 0)
        gfx.unlockFocus()
        textImage:drawScaled((400 - textWidth * scale) / 2, y, scale)
        gfx.popContext()
    else

        for i, action in ipairs(self.actions) do
            local scale = self.scales[i]
            local y = self.yPositions[i]
            local controlKey = self.controls[action]
            local mappedControl = controlKey and self.controlMapping[controlKey] or "Unknown"
            local text = string.format("%s: %s", action, mappedControl)
            local textWidth, textHeight = gfx.getTextSize(text)

            gfx.pushContext()
            local textImage = gfx.image.new(textWidth * scale, textHeight * scale)
            gfx.lockFocus(textImage)
            gfx.drawText(text, 0, 0)
            gfx.unlockFocus()
            textImage:drawScaled((400 - textWidth * scale) / 2, y, scale)
            gfx.popContext()
        end
    end
end

function ControlsState:handleInput()
    if self.isEditing then
        self:handleEditingInput()
        return
    end

    if playdate.buttonJustPressed(playdate.kButtonUp) then
        self:changeSelection(-1)
    elseif playdate.buttonJustPressed(playdate.kButtonDown) then
        self:changeSelection(1)
    elseif playdate.buttonJustPressed(playdate.kButtonA) then
        self:startEditing()
    elseif playdate.buttonJustPressed(playdate.kButtonB) then
        self:exitToOptions()
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


function ControlsState:handleEditingInput()
    local buttons = {
        playdate.kButtonLeft,
        playdate.kButtonRight,
        playdate.kButtonUp,
        playdate.kButtonDown,
        playdate.kButtonA,      
        playdate.kButtonB       
    }

    local buttonNameMap = {
        [playdate.kButtonLeft]  = "playdate.kButtonLeft",
        [playdate.kButtonRight] = "playdate.kButtonRight",
        [playdate.kButtonUp]    = "playdate.kButtonUp",
        [playdate.kButtonDown]  = "playdate.kButtonDown",
        [playdate.kButtonA]     = "playdate.kButtonA",
        [playdate.kButtonB]     = "playdate.kButtonB"
    }

    for _, button in ipairs(buttons) do
        if playdate.buttonJustPressed(button) then
            local buttonName = buttonNameMap[button]
            if buttonName then
                local selectedAction = self.actions[self.selectedIndex]
                if not selectedAction then
                    print("Error: selectedAction is nil!")
                else
                    self.controls[selectedAction] = buttonName
                    self:saveControls()
                    self.isEditing = false
                    print(string.format("Rebound '%s' to '%s'", selectedAction, buttonName)) 
                end
            else

                print("Warning: Unknown button pressed.")
            end
            break
        end
    end
end

function ControlsState:startEditing()
    self.isEditing = true
end

function ControlsState:changeSelection(direction)
    self.selectedIndex = self.selectedIndex + direction
    if self.selectedIndex < 1 then
        self.selectedIndex = #self.actions
    elseif self.selectedIndex > #self.actions then
        self.selectedIndex = 1
    end
    if self.SoundHandler then
        self.SoundHandler:playScroll()
    end
    print(string.format("Selected Index: %d, Action: %s", self.selectedIndex, self.actions[self.selectedIndex]))
end

function ControlsState:exitToOptions()
    self.stateManager:switchTo("options")
end

return ControlsState