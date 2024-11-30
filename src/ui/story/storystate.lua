import "CoreLibs/graphics"
import "../title/titlestate"

local gfx <const> = playdate.graphics

class("StoryState").extends()

function StoryState:init(mainMenuState, titleState, stateManager)
    StoryState.super.init(self)
    self.stateManager = stateManager
    self.mainMenuState = mainMenuState 
    self.titleState = titleState 
end

function StoryState:update()
    gfx.clear(gfx.kColorBlack)
    gfx.drawTextAligned("Story Mode", 200, 120, kTextAlignment.center)
    
    self:handleInput()
end

function StoryState:handleInput()
    if playdate.buttonJustPressed(playdate.kButtonB) then
        self.stateManager:switchTo("mainMenu")
    end
end