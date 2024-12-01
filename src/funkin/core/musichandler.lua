class("MusicHandler").extends()

function MusicHandler:init(musicPath)
    assert(musicPath and #musicPath > 0, "Error: musicPath must be a valid string.")
    self.musicPath = musicPath
    self.currentMusic = nil
    self.currentTrack = nil
    self.isPlaying = false
end

function MusicHandler:playMusic(fileName)
    if self.currentTrack == fileName and self.isPlaying then
        return
    end
    self.currentMusic = songName
    if self.currentMusic then
        self.currentMusic:stop()
    end

    local fullPath = self.musicPath .. fileName
    self.currentMusic = playdate.sound.fileplayer.new(fullPath)
    assert(self.currentMusic, "Error: Failed to load music at path: " .. fullPath)
    self.currentMusic:setVolume(1)

    self.currentMusic:setFinishCallback(function()
        self.currentMusic:play()
    end)

    self.currentMusic:play()
    self.currentTrack = fileName
    self.isPlaying = true
end

function MusicHandler:pauseMusic()
    if self.currentMusic and self.isPlaying then
        self.currentMusic:pause()
        self.isPlaying = false
    end
end

function MusicHandler:resumeMusic()
    if self.currentMusic and not self.isPlaying then
        self.currentMusic:play()
        self.isPlaying = true
    end
end

function MusicHandler:stopMusic()
    if self.currentMusic then
        self.currentMusic:stop()
        self.currentTrack = nil
        self.isPlaying = false
        self.currentMusic = nil
    end
end

function MusicHandler:getCurrentMusic()
    return self.currentTrack
end

function MusicHandler:setPlaybackRate(rate)
    if self.currentMusic then
        self.currentMusic:setRate(rate)
    end
end

function MusicHandler:continuous()
    if self.currentMusic and self.isPlaying then
        return
    elseif self.currentMusic then
        self:resumeMusic()
    end
end
