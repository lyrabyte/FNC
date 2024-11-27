import "CoreLibs/graphics"
import "../title/titlestate"

local gfx <const> = playdate.graphics

class("OptionsState").extends()

function OptionsState:init(introMusic, mainMenuState, titleState, stateManager)
    OptionsState.super.init(self)
    self.stateManager = stateManager

    self.mainMenuState = mainMenuState 
    self.titleState = titleState 
    
end

function OptionsState:update()
    gfx.clear(gfx.kColorBlack) 

    
    gfx.drawTextAligned("Options Mode", 200, 120, kTextAlignment.center)
    
    if self.titleState.introMusic:isPlaying() then
        self.titleState.introMusic:pause()
    end
    
    self:handleInput()
end

function OptionsState:handleInput()
    if playdate.buttonJustPressed(playdate.kButtonB) then
        
        self.mainMenuState:resetWipe()
        
        
        self.stateManager:switchTo("mainMenu")
    end
end