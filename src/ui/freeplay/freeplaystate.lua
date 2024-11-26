import "CoreLibs/graphics"
import "../title/titlestate"

local gfx <const> = playdate.graphics

class("FreeplayState").extends()

function FreeplayState:init(mainMenuState, titleState, freeplayPath)
    FreeplayState.super.init(self)
    
    self.mainMenuState = mainMenuState 
    self.titleState = titleState 
    
end

function FreeplayState:update()
    gfx.clear(gfx.kColorBlack) 

    
    gfx.drawTextAligned("Freeplay Mode", 200, 120, kTextAlignment.center)
    
    if self.titleState.introMusic:isPlaying() then
        self.titleState.introMusic:pause()
    end
    
    self:handleInput()
end

function FreeplayState:handleInput()
    if playdate.buttonJustPressed(playdate.kButtonB) then
        
        self.mainMenuState:resetWipe()
        
        
        currentState = self.mainMenuState
    end
end