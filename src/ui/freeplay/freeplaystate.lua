import "CoreLibs/graphics"
import "../title/titlestate"

local gfx <const> = playdate.graphics

class("FreeplayState").extends()

function FreeplayState:init(mainMenuState, titleState, stateManager)
    FreeplayState.super.init(self)
    self.stateManager = stateManager

    self.mainMenuState = mainMenuState 
    self.titleState = titleState 
    
end

function FreeplayState:update()
    gfx.clear(gfx.kColorBlack) 

    
    gfx.drawTextAligned("Freeplay Mode", 200, 120, kTextAlignment.center)
    
    self:handleInput()
end

function FreeplayState:handleInput()
    if playdate.buttonJustPressed(playdate.kButtonB) then
        self.stateManager:switchTo("mainMenu")
    end
end