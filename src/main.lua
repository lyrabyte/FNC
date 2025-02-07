import "CoreLibs/graphics"
import "CoreLibs/timer"
import "CoreLibs/object"

import "/funkin/core/statemanager"
import "/ui/title/titlestate"
import "/ui/mainmenu/mainmenustate"
import "/ui/options/optionsstate"
import "/ui/options/controls"
import "/ui/credits/creditsstate"
import "/ui/story/storystate"
import "/funkin/core/SoundHandler"
import "/funkin/music/conductor"
import "/funkin/core/MusicHandler"

local gfx <const> = playdate.graphics

-- asset path init lol
local funkinMusic = "assets/music/"
local funkinSounds = "assets/sounds/"
local funkinImages = "assets/images/"
local funkinFont = gfx.font.new("assets/fonts/phantommuff")
local funkinWeekFnt = gfx.font.new("assets/fonts/FNFWeekTextFont-Regular")
local introTexts = "assets/data/introTexts.txt"
local musicPath = "assets/music/title/freakyMenu"
local controls = "assets/data/controls/controls.json"

local conductor = Conductor(musicPath)

local stateManager = StateManager()

local SoundHandler = SoundHandler(funkinSounds)
local MusicHandler = MusicHandler(funkinMusic)

local titleScreen = TitleState(
    stateManager,
    conductor,
    musicPath,
    funkinMusic,
    funkinSounds,
    funkinImages,
    funkinFont,
    introTexts,
    nil,
    SoundHandler,
    MusicHandler
)

local mainMenuState = MainMenuState(
    funkinMusic,
    funkinSounds,
    funkinImages,
    titleScreen,
    stateManager,
    SoundHandler,
    MusicHandler
)

local freeplayState = FreeplayState(
    mainMenuState,
    titleScreen,
    stateManager,
    funkinImages,
    SoundHandler
)

local optionsState = OptionsState(
    funkinWeekFnt,
    funkinImages,
    mainMenuState,
    titleScreen,
    stateManager,
    SoundHandler,
    MusicHandler
)

local Controls = Controls(
    funkinWeekFnt,
    funkinSounds,
    funkinImages,
    optionsState,
    controls,
    stateManager,
    SoundHandler,
    MusicHandler
)

local storyState = StoryState(
    mainMenuState,
    titleScreen,
    stateManager,
    SoundHandler,
    MusicHandler
)

local creditsState = CreditsState(
    mainMenuState,
    titleScreen,
    funkinFont,
    funkinMusic,
    stateManager,
    MusicHandler
)


titleScreen.mainMenuState = mainMenuState
mainMenuState.freeplayState = freeplayState

-- state init lol
stateManager:addState("title", titleScreen)
stateManager:addState("mainMenu", mainMenuState)
stateManager:addState("freeplay", freeplayState)
stateManager:addState("options", optionsState)
stateManager:addState("controls", Controls)
stateManager:addState("credits", creditsState)
stateManager:addState("story", storyState)

stateManager:switchTo("title")

function playdate.update()
    stateManager:update()
    playdate.timer.updateTimers()
end
