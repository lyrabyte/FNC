import "CoreLibs/graphics"

local gfx <const> = playdate.graphics

class("WipeTransition").extends()

function WipeTransition:init(wipeSpeed, screenWidth, screenHeight)
    WipeTransition.super.init(self)
    
    self.wipeSpeed = wipeSpeed or 20
    self.screenWidth = screenWidth or 400
    self.screenHeight = screenHeight or 240
    self.wipeHeight = 0
    self.wipeCompleted = false
end

function WipeTransition:reset()
    self.wipeHeight = 0
    self.wipeCompleted = false
end

function WipeTransition:update()
    if not self.wipeCompleted then
        self:performWipe()
    end
end

function WipeTransition:performWipe()
    for i = 0, self.wipeHeight - 1 do
        local alpha = 1 - (i / self.wipeHeight)
        gfx.setDitherPattern(alpha, gfx.image.kDitherTypeBayer4x4)
        gfx.fillRect(0, i, self.screenWidth, 1)
    end

    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, self.wipeHeight, self.screenWidth, self.screenHeight - self.wipeHeight)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    self.wipeHeight = self.wipeHeight + self.wipeSpeed

    if self.wipeHeight >= self.screenHeight then
        self.wipeHeight = self.screenHeight
        self.wipeCompleted = true
    end
end

function WipeTransition:isCompleted()
    return self.wipeCompleted
end