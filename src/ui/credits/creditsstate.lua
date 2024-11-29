import "CoreLibs/graphics"
import "CoreLibs/ui"

local gfx <const> = playdate.graphics

class("CreditsState").extends()

function CreditsState:init(introMusic, mainMenuState, titleState, funkinFont, funkinMusic, stateManager, MusicHandler)
    CreditsState.super.init(self)
    self.stateManager = stateManager
    self.mainMenuState = mainMenuState
    self.musicHandler = MusicHandler
    self.titleState = titleState 
    self.introMusic = introMusic
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
    local y = 0 

    local credits = {
        {header = "Friday Night Crankin", body = {"ported by", "Lyrabyte"}},
        {header = "Fonts", body = {"Phantommuff Font", "Created by Cracsthor"}},
        {header = "Friday Night Funkin'", body = {"A video game created by", "The Funkin' Crew Inc."}},
        {header = "The Funkin' Crew Inc. Shareholders", body = {"ninjamuffin99", "PhantomArcade", "Kawai Sprite", "evilsk8r"}},
        {header = "Direction and Art Lead", body = {"PhantomArcade"}},
        {header = "Music Lead", body = {"Isaac 'Kawai Sprite' Garcia"}},
        {header = "Co-Direction and Programming Lead", body = {"ninjamuffin99"}},
        {header = "Producer", body = {"Kawa Teano"}},
        {header = "Artists", body = {"PhantomArcade", "evilsk8r", "beck"}},
        {header = "Pixel Art", body = {"moawling"}},
        {header = "Cutscene Storyboards & SFX", body = {"PhantomArcade"}},
        {header = "Additional Background Design", body = {"Red Minus"}},
        {header = "Cutscene Animation", body = {"Figburn", "Sade", "Topium", "BlairTheUnseriousGuy"}},
        {header = "Cutscene Cleanup", body = {"PennilessRagamuffin", "beck"}},
        {header = "Cutscene Background Art", body = {"beck"}},
        {header = "Additional Art", body = {"Jeff Bandelin", "Mogy64", "ChipsGoWoah", "Min Ho Kim (Deegeemin)", "PKettles", "peepo173"}},
        {header = "Music Production", body = {"Saruky", "crisp"}},
        {header = "Featured Guest Musicians (thus far)", body = {"BassetFilms", "Kohta Takahashi", "Lotus Juice", "METAROOM", "nuphory", "Saster", "SixImpala", "TeraVex", "ThatAndyGuy", "tsuyunoshi", "xploshi"}},
        {header = "Programming", body = {"Eric 'EliteMasterEric' Myllyoja", "fabs"}},
        {header = "Additional Programming", body = {"Jenny Crowe", "ember ana", "Mike Welsh", "Saharan", "Ian Harrigan", "Osaka Red LLC: Thomas J Webb", "Emma (MtH)", "George Kurelic", "Will Blanton", "Victor - Cheemsandfriends"}},
        {header = "Devops and Additional Internal Tooling", body = {"ember ana"}},
        {header = "Gameplay Design", body = {"PhantomArcade", "Cameron Taylor", "Jenny Crowe", "Spazkid", "fabs", "Emma (MtH)"}},
        {header = "Kickstarter Backer Portal Programming", body = {"Shingai Shamu"}},
        {header = "Special Thanks", body = {"Tom Fulp", "Jeff Bandelin", "The entire Molinari Oswald Crew", "The entire Odin Law function", "SrPelo"}}
    }

    for _, entry in ipairs(credits) do
        table.insert(self.textBlocks, {text = entry.header, y = y, isHeader = true})
        y += 18 * self.headerScale + self.lineSpacing 

        for _, line in ipairs(entry.body) do
            table.insert(self.textBlocks, {text = line, y = y, isHeader = false})
            y += 16 * self.bodyScale + self.lineSpacing 
        end

        y += 20 
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
            local rectY = textY

            gfx.setFont(self.funkinFont)
            gfx.drawTextInRect(block.text, rectX, rectY, rectWidth, rectHeight, nil, "...", kTextAlignment.center)
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

    self.scrollY += self.scrollSpeed

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

        if self.creditsMusic then

            local pitchChange = 0.01 * crankChange 
            local playbackRate = 1 + pitchChange 
            playbackRate = math.max(0.5, math.min(2, playbackRate)) 
        end
    else

        self.scrollSpeed = 0.5

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