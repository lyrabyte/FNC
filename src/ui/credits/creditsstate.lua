import "CoreLibs/graphics"
import "CoreLibs/ui"
import "/funkin/libs/json"

local gfx <const> = playdate.graphics

class("CreditsState").extends()

function CreditsState:init(mainMenuState, titleState, funkinFont, funkinMusic, stateManager, MusicHandler, creditsFile)
    CreditsState.super.init(self)
    
    self.stateManager = stateManager
    self.mainMenuState = mainMenuState
    self.musicHandler = MusicHandler
    self.titleState = titleState 
    self.funkinFont = funkinFont
    self.funkinMusic = funkinMusic
    self.creditsMusic = "library/freeplayRandom"
    
    self.previousMusic = nil
    self.textBlocks = {}
    self.scrollY = -250 
    self.scrollSpeed = 0.5 
    self.lineSpacing = 12 
    self.headerScale = 2 
    self.bodyScale = 1 
    
    self.creditsFile = creditsFile or "assets/data/credits.json"
    
    self:loadCredits()
    self.totalHeight = self:calculateTotalHeight()
end

function CreditsState:onEnter()
    print("CreditsState:onEnter triggered!") 
    self.previousMusic = self.musicHandler:getCurrentMusic()
    self.musicHandler:stopMusic()
    self.musicHandler:playMusic(self.creditsMusic)
end

function CreditsState:onExit()
    self.musicHandler:stopMusic()
    if self.previousMusic then
        self.musicHandler:playMusic(self.previousMusic)
    end
    self.scrollY = -250 
end

function CreditsState:loadCredits()
    local file = playdate.file.open(self.creditsFile, playdate.file.kFileRead)
    if not file then
        error("CreditsState: Failed to open credits file: " .. self.creditsFile)
    end

    local fileContent = ""
    while true do
        local line = file:readline()
        if not line then break end
        fileContent = fileContent .. line
    end
    file:close()

    local success, data = pcall(json.decode, fileContent)
    if not success then
        error("CreditsState: Failed to decode credits JSON: " .. data)
    end
    if not data.credits then
        error("CreditsState: No 'credits' key found in JSON data")
    end

    local credits = data.credits
    local y = 0
    for _, entry in ipairs(credits) do
        table.insert(self.textBlocks, { text = entry.header, y = y, isHeader = true })
        y = y + (18 * self.headerScale + self.lineSpacing)
        for _, line in ipairs(entry.body) do
            table.insert(self.textBlocks, { text = line, y = y, isHeader = false })
            y = y + (16 * self.bodyScale + self.lineSpacing)
        end
        y = y + 20
    end
end

function CreditsState:calculateTotalHeight()
    local totalHeight = 0
    for _, block in ipairs(self.textBlocks) do
        totalHeight = math.max(totalHeight, block.y)
    end
    return totalHeight + 30
end

function CreditsState:update()
    gfx.clear(gfx.kColorBlack) 
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)

    for _, block in ipairs(self.textBlocks) do
        local textY = block.y - self.scrollY
        if textY > -28 and textY < 240 then 
            local scale = block.isHeader and self.headerScale or self.bodyScale
            local rectHeight = 28 * scale 
            local rectWidth = 400 
            local rectX = 200 - (rectWidth / 2) 
            gfx.setFont(self.funkinFont)
            gfx.drawTextInRect(block.text, rectX, textY, rectWidth, rectHeight, nil, "...", kTextAlignment.center)
        end
    end

    if playdate.isCrankDocked() then
        if playdate.ui.crankIndicator then
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
            playdate.ui.crankIndicator:update() 
        else
            playdate.ui.crankIndicator = playdate.ui.crankIndicator or playdate.ui.newCrankIndicator()
            playdate.ui.crankIndicator:start()
        end
    end

    self:adjustScrollAndMusic()
    self.scrollY = self.scrollY + self.scrollSpeed

    if self.scrollY < -250 then
        self.scrollY = -250
    end

    if self.scrollY >= self.totalHeight then
        self:exitToMainMenu()
        return
    end

    self:handleInput()
end

function CreditsState:adjustScrollAndMusic()
    if playdate.isCrankDocked() then
        self.scrollSpeed = 0.5
        return
    end

    local crankChange = playdate.getCrankChange()

    if crankChange ~= 0 then
        self.scrollSpeed = crankChange * 0.5

        if self.creditsMusic and self.musicHandler then
            local pitchChange = 0.01 * crankChange
            local playbackRate = 1 + pitchChange
            playbackRate = math.max(0.5, math.min(2, playbackRate))
            self.musicHandler:setPlaybackRate(playbackRate)
        end
    else
        self.scrollSpeed = 0.5
        if self.musicHandler then
            self.musicHandler:setPlaybackRate(1)
        end
    end
end

function CreditsState:exitToMainMenu()
    self.musicHandler:stopMusic()
    self.scrollY = -250 
    self.stateManager:switchTo("mainMenu")
end

function CreditsState:handleInput()
    if playdate.buttonJustPressed(playdate.kButtonB) then
        self.stateManager:switchTo("mainMenu")
    end
end

return CreditsState
