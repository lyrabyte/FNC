import "CoreLibs/object"

class("SoundHandler").extends()

function SoundHandler:init(funkinSounds, confirmSoundPath)
    SoundHandler.super.init(self)
    
    self.scrollSoundPath = funkinSounds .. "menus/scroll"
    self.scrollSound = playdate.sound.sampleplayer.new(self.scrollSoundPath)
    
    if not self.scrollSound then
        print("Error: Failed to load scroll sound from " .. self.scrollSoundPath)
    else
        self.scrollSound:setVolume(1.0)
    end
    
    self.confirmSoundPath = confirmSoundPath or (funkinSounds .. "menus/confirm")
    self.confirmSound = playdate.sound.sampleplayer.new(self.confirmSoundPath)
    
    if not self.confirmSound then
        print("Error: Failed to load confirm sound from " .. self.confirmSoundPath)
    else
        self.confirmSound:setVolume(1.3)
    end
end

function SoundHandler:playScroll()
    if self.scrollSound then
        self.scrollSound:play()
    else
        print("Error: Scroll sound is not set or is invalid.")
    end
end

function SoundHandler:playConfirm()
    if self.confirmSound then
        self.confirmSound:play()
    else
        print("Error: Confirm sound is not set or is invalid.")
    end
end

return SoundHandler
