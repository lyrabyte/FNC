import "CoreLibs/graphics"
import "CoreLibs/timer"
import "CoreLibs/object"

import "/funkin/core/statemanager"
import "/ui/title/titlestate"
import "/ui/mainmenu/mainmenustate"
import "/ui/options/optionsstate"
import "/ui/credits/creditsstate"
import "/ui/story/storystate"

import "/funkin/music/conductor"

local gfx <const> = playdate.graphics

-- asset path init lol
local funkinMusic = "assets/music/"
local funkinSounds = "assets/sounds/"
local funkinImages = "assets/images/"
local funkinFont = gfx.font.new("assets/fonts/phantommuff")
local introTexts = "assets/data/introTexts.txt"
local musicPath = "assets/music/title/freakyMenu"

local conductor = Conductor(musicPath)

local introMusic = playdate.sound.fileplayer.new(musicPath)

local stateManager = StateManager()

local titleScreen = TitleState(stateManager, conductor, introMusic, funkinMusic, funkinSounds, funkinImages, funkinFont, introTexts, nil)
local mainMenuState = MainMenuState(introMusic, funkinMusic, funkinSounds, funkinImages, titleScreen, stateManager)
local freeplayState = FreeplayState(introMusic, mainMenuState, titleScreen, stateManager)
local optionsState = OptionsState(introMusic, mainMenuState, titleScreen, stateManager)
local storyState = StoryState(introMusic, mainMenuState, titleScreen, stateManager)
local creditsState = CreditsState(introMusic, mainMenuState, titleState, funkinFont, funkinMusic, stateManager)

titleScreen.mainMenuState = mainMenuState
mainMenuState.freeplayState = freeplayState

-- state init lol
stateManager:addState("title", titleScreen)
stateManager:addState("mainMenu", mainMenuState)
stateManager:addState("freeplay", freeplayState)
stateManager:addState("options", optionsState)
stateManager:addState("credits", creditsState)
stateManager:addState("story", storyState)

stateManager:switchTo("title")

function playdate.update()
    stateManager:update()
    playdate.timer.updateTimers()
end