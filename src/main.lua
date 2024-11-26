import "CoreLibs/graphics"
import "CoreLibs/timer"
import "CoreLibs/object"

import "/ui/title/titlestate"
import "/ui/mainmenu/mainmenustate"
import "/funkin/music/conductor"

local gfx <const> = playdate.graphics

local funkinPath = "assets/images/funkin"
local mainMenuBG = "assets/images/mainmenu/menuBG"

local gfDanceTitle = "assets/images/title/gfDanceTitle"
local gfRingTone = "assets/music/title/girlfriendsRingtone"

local introTexts = "assets/data/introTexts.txt"
local mainMenuPath = "assets/images/mainmenu/"
local menuAudioPath = "assets/sounds/menus/"
local freeplayPath = "assets/images/freeplay/"

local musicPath = "assets/music/title/freakyMenu"
local confirm = "assets/sounds/menus/Confirm"

local phantomMuffFont = gfx.font.new("assets/fonts/phantommuff")

local conductor = Conductor(musicPath)

local introMusic = playdate.sound.fileplayer.new(musicPath)

local titleScreen = nil
local mainMenuState = nil
local freeplayState = nil

titleScreen = TitleState(conductor, introMusic, funkinPath, gfDanceTitle, gfRingTone, confirm, phantomMuffFont, introTexts, nil)

mainMenuState = MainMenuState(mainMenuBG, mainMenuPath, menuAudioPath, titleScreen)
freeplayState = FreeplayState(mainMenuState, titleScreen, freeplayPath)

titleScreen.mainMenuState = mainMenuState
mainMenuState.freeplayState = freeplayState

currentState = titleScreen

function playdate.update()
    if currentState and currentState.update then
        currentState:update()
    end
    playdate.timer.updateTimers()
end
