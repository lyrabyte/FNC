import "CoreLibs/object"
import "CoreLibs/timer"
import "../libs/json" 

class("Conductor").extends()

function Conductor:init(musicPath)
    Conductor.super.init(self)

    
    self.musicPath = musicPath
    self.metadataPath = musicPath .. "-metadata.json"

    
    self.bpm = 120
    self.timeSignatureNumerator = 4
    self.timeSignatureDenominator = 4
    self.stepsPerBeat = 4 
    self.beatsPerMeasure = self.timeSignatureNumerator
    self.stepLengthMs = (60 / self.bpm) * 1000 / self.stepsPerBeat
    self.globalStep = 0
    self.currentTimeMs = 0
    self.lastStepTime = playdate.getCurrentTimeMilliseconds() 

    
    self.onStepHitCallbacks = {}

    
    self:parseMetadata()

    
    self:startStepTimer()
end

function Conductor:parseMetadata()
    local metadataFile = playdate.file.open(self.metadataPath, playdate.file.kReadMode)

    if metadataFile then
        
        local fileContent = ""
        local chunkSize = 256 
        while true do
            local chunk = metadataFile:read(chunkSize)
            if not chunk or #chunk == 0 then
                break
            end
            fileContent = fileContent .. chunk
        end
        metadataFile:close()

        if fileContent and #fileContent > 0 then
            
            local success, metadata = pcall(json.decode, fileContent)

            if success and metadata then
                print("Conductor: Successfully parsed metadata.")

                
                if metadata.timeChanges and type(metadata.timeChanges) == "table" then
                    for _, change in ipairs(metadata.timeChanges) do
                        
                        if type(change) == "table" then
                            self:scheduleTimeChange(change)
                        else
                            print("Conductor: Skipping invalid time change entry.")
                        end
                    end
                else
                    print("Conductor: No valid timeChanges found in metadata. Using default BPM and Time Signature.")
                    self:setBPM(self.bpm)
                    self:setTimeSignature(self.timeSignatureNumerator, self.timeSignatureDenominator)
                end
            else
                print("Conductor: Failed to parse JSON. Using default BPM and Time Signature.")
                self:setBPM(self.bpm)
                self:setTimeSignature(self.timeSignatureNumerator, self.timeSignatureDenominator)
            end
        else
            print("Conductor: Metadata file is empty or invalid. Using default BPM and Time Signature.")
            self:setBPM(self.bpm)
            self:setTimeSignature(self.timeSignatureNumerator, self.timeSignatureDenominator)
        end
    else
        print("Conductor: Metadata file not found. Using default BPM and Time Signature.")
        self:setBPM(self.bpm)
        self:setTimeSignature(self.timeSignatureNumerator, self.timeSignatureDenominator)
    end
end

function Conductor:resume()
    self.lastStepTime = playdate.getCurrentTimeMilliseconds()
end

function Conductor:scheduleTimeChange(change)
    
    local bpm = tonumber(change.bpm) or self.bpm
    local n = tonumber(change.n) or self.timeSignatureNumerator
    local d = tonumber(change.d) or self.timeSignatureDenominator
    local t = tonumber(change.t) or 0
    local bt = change.bt or {self.beatsPerMeasure}

    
    if type(bt) ~= "table" then
        bt = {self.beatsPerMeasure}
    end

    
    playdate.timer.performAfterDelay(t, function()
        print(string.format("Conductor: Applying timeChange at %d ms - BPM: %d, Time Signature: %d/%d", t, bpm, n, d))
        self:setBPM(bpm)
        self:setTimeSignature(n, d)

        
        
        
    end)
end

function Conductor:setBPM(newBPM)
    if newBPM ~= self.bpm then
        self.bpm = newBPM
        self.stepLengthMs = (60 / self.bpm) * 1000 / self.stepsPerBeat
        print(string.format("Conductor: BPM set to %d. Step Length: %.2f ms", self.bpm, self.stepLengthMs))
        self:restartStepTimer()
    end
end

function Conductor:setTimeSignature(numerator, denominator)
    if numerator ~= self.timeSignatureNumerator or denominator ~= self.timeSignatureDenominator then
        self.timeSignatureNumerator = numerator
        self.timeSignatureDenominator = denominator
        self.beatsPerMeasure = self.timeSignatureNumerator
        print(string.format("Conductor: Time Signature set to %d/%d", self.timeSignatureNumerator, self.timeSignatureDenominator))
    end
end

function Conductor:restartStepTimer()
    if self.stepTimer then
        self.stepTimer:remove()
    end
    self:startStepTimer()
end

function Conductor:startStepTimer()
    self.stepTimer = playdate.timer.new(self.stepLengthMs, function()
        self:updateStep()
    end)
    self.stepTimer.repeats = true
end

function Conductor:updateStep()
    self.globalStep += 1
    self.currentTimeMs += self.stepLengthMs
    self.lastStepTime = playdate.getCurrentTimeMilliseconds() 
    self:dispatchStepHit()
end

function Conductor:update()
    playdate.timer.updateTimers()
end

function Conductor:onStepHit(callback)
    table.insert(self.onStepHitCallbacks, callback)
end

function Conductor:dispatchStepHit()
    print("Conductor: Global Step Hit - " .. self.globalStep)
    for _, callback in ipairs(self.onStepHitCallbacks) do
        callback(self.globalStep)
    end
end

function Conductor:setDynamicBPM(newBPM)
    self:setBPM(newBPM)
end

return Conductor