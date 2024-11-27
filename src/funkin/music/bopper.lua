import "CoreLibs/object"

class("Bopper").extends()

function Bopper:init(conductor)
    Bopper.super.init(self)

    if not conductor or type(conductor.onStepHit) ~= "function" then
        error("Invalid Conductor passed to Bopper.")
    end

    self.conductor = conductor
    self.shouldBop = true
    self.beatScale = 0.04
    self.bumpTriggered = false
    self.bumpValue = 0
    self.lastBopTime = 0
    self.bopFrequencyMultiplier = 1 

    self.conductor:onStepHit(function(step)
        self:onStepHit(step)
    end)
end

function Bopper:onStepHit(step)
    
    if self.shouldBop and (step % math.ceil(4 / self.bopFrequencyMultiplier) == 0) then
        self:playAnimation()
    end
end

function Bopper:setBopFrequencyMultiplier(multiplier)
    self.bopFrequencyMultiplier = math.max(0.1, multiplier) 
end

function Bopper:playAnimation()
    self.bumpTriggered = true
    self.lastBopTime = playdate.getCurrentTimeMilliseconds()
end

function Bopper:update()
    
    if self.bumpTriggered then
        local elapsed = playdate.getCurrentTimeMilliseconds() - self.lastBopTime
        local duration = self.conductor.stepLengthMs
        if elapsed < duration then
            self.bumpValue = math.sin((elapsed / duration) * math.pi) * self.beatScale
        else
            self.bumpTriggered = false
            self.bumpValue = 0
        end
    end
end

function Bopper:getBumpValue()
    return self.bumpValue or 0
end

return Bopper