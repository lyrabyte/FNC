import "CoreLibs/graphics"
import "CoreLibs/timer"
import "CoreLibs/object"
import "/funkin/libs/json"
import "../../funkin/core/wipetransition"

local gfx <const> = playdate.graphics

class("FreeplayState").extends()

function FreeplayState:init(mainMenuState, titleState, stateManager, funkinImages, SoundHandler)
    FreeplayState.super.init(self)
    self.funkinImages = funkinImages or "assets/images/"
    self.stateManager = stateManager
    self.mainMenuState = mainMenuState
    self.titleState = titleState
    self.SoundHandler = SoundHandler

    self.font = gfx.font.new("assets/fonts/FNFWeekTextFont-Regular")

    self.menuBGInv = gfx.image.new(self.funkinImages .. "mainmenu/menuBGInv")
    if not self.menuBGInv then
        error("FreeplayState: Failed to load background image from " .. self.funkinImages .. "mainmenu/menuBGInv")
    end
    self.zoomFactor = 1.3
    self.scaledBG = self:scaleImageToFit(self.menuBGInv, 400 * self.zoomFactor, 240 * self.zoomFactor)
    self.scaledBGWidth, self.scaledBGHeight = self.scaledBG:getSize()

    self.songs = {}
    self.songScales = {}
    self.songYPositions = {}
    self.selectedSongIndex = 1

    self.listStartY = 50
    self.listItemSpacing = 30
    self.listScrollOffset = 0
    self.targetListScrollOffset = 0

    self.baseScale = 1.0
    self.selectedScale = 1.5
    self.animationSpeed = 0.2

    self:loadSongs()
    if #self.songs > 0 then
        for i = 1, #self.songs do
            self.songScales[i] = self.baseScale
            self.songYPositions[i] = self.listStartY + (i - 1) * self.listItemSpacing
        end
    end

    self.wipeTransition = WipeTransition(8, 400, 240)
end

function FreeplayState:scaleImageToFit(image, targetWidth, targetHeight)
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

function FreeplayState:loadSongs()
    local songDataDir = "assets/data/songs/"
    local entries = playdate.file.listFiles(songDataDir)
    if entries then
        for _, entry in ipairs(entries) do
            if entry:sub(-1) == "/" then
                local folderName = entry:sub(1, -2)
                local metadataPath = songDataDir .. folderName .. "/" .. folderName .. "-metadata.json"
                if playdate.file.exists(metadataPath) then
                    local file = playdate.file.open(metadataPath, playdate.file.kReadMode)
                    if file then
                        local content = ""
                        while true do
                            local line = file:readline()
                            if not line then break end
                            content = content .. line
                        end
                        file:close()
                        local success, metadata = pcall(json.decode, content)
                        if success and metadata then
                            table.insert(self.songs, metadata)
                        else
                            print("FreeplayState: Failed to decode metadata in " .. metadataPath)
                        end
                    end
                else
                    print("FreeplayState: Metadata file not found for song folder: " .. folderName)
                end
            end
        end
    else
        print("FreeplayState: No entries found in " .. songDataDir)
    end
end

function FreeplayState:onEnter()
    self.wipeTransition:reset()
end

function FreeplayState:update()
    gfx.clear(gfx.kColorBlack)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    local bgX = (400 - self.scaledBGWidth) / 2
    local bgY = (240 - self.scaledBGHeight) / 2
    self.scaledBG:draw(bgX, bgY)

    gfx.setFont(self.font)

    if #self.songs == 0 then
        gfx.drawTextAligned("No songs found.", 200, 120, kTextAlignment.center)
    else
        for i = 1, #self.songs do
            local targetScale = (i == self.selectedSongIndex) and self.selectedScale or self.baseScale
            self.songScales[i] = self.songScales[i] + (targetScale - self.songScales[i]) * self.animationSpeed
            local targetY = self.listStartY + (i - 1) * self.listItemSpacing
            self.songYPositions[i] = self.songYPositions[i] + (targetY - self.songYPositions[i]) * self.animationSpeed
        end

        local desiredCenterY = 120
        self.targetListScrollOffset = self.songYPositions[self.selectedSongIndex] - desiredCenterY
        self.listScrollOffset = self.listScrollOffset +
        (self.targetListScrollOffset - self.listScrollOffset) * self.animationSpeed

        for i, song in ipairs(self.songs) do
            local title = song.songName or "Unknown"
            local scale = self.songScales[i]
            local textWidth = self.font:getTextWidth(title)
            local textHeight = self.font:getHeight()
            local textImage = gfx.image.new(textWidth, textHeight)
            gfx.pushContext(textImage)
            gfx.clear(gfx.kColorClear)
            gfx.drawText(title, 0, 0)
            gfx.popContext()
            local x = 20
            local y = self.songYPositions[i] - self.listScrollOffset
            textImage:drawScaled(x, y, scale)
        end
    end

    self:handleInput()

    self.wipeTransition:update()
    if not self.wipeTransition:isCompleted() then
        self.wipeTransition:performWipe()
    end
end

function FreeplayState:handleInput()
    if playdate.buttonJustPressed(playdate.kButtonUp) then
        self.selectedSongIndex = self.selectedSongIndex - 1
        if self.selectedSongIndex < 1 then
            self.selectedSongIndex = #self.songs
        end
        if self.SoundHandler then
            self.SoundHandler:playScroll()
        end
    elseif playdate.buttonJustPressed(playdate.kButtonDown) then
        self.selectedSongIndex = self.selectedSongIndex + 1
        if self.selectedSongIndex > #self.songs then
            self.selectedSongIndex = 1
        end
        if self.SoundHandler then
            self.SoundHandler:playScroll()
        end
    elseif playdate.buttonJustPressed(playdate.kButtonA) then
        local song = self.songs[self.selectedSongIndex]
        print("Selected song: " .. (song.songName or "Unknown"))
    elseif playdate.buttonJustPressed(playdate.kButtonB) then
        self.stateManager:switchTo("mainMenu")
    end
end

return FreeplayState
