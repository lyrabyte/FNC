local gfx <const> = playdate.graphics

class("StateManager").extends()

function StateManager:init()
    StateManager.super.init(self)
    self.states = {}               -- Store all states
    self.currentState = nil        -- Current active state
    self.previousState = nil       -- Last active state for transitions
    self.transitioning = false     -- If a transition is in progress
    self.transitionCallback = nil  -- Callback for transition completion
end

function StateManager:addState(name, state)
    if not name or not state then
        error("Error: State name and instance must be provided!")
    end
    self.states[name] = state
end

function StateManager:switchTo(stateName, transitionData)
    if self.transitioning then
        print("Error: Already in a transition!")
        return
    end

    local nextState = self.states[stateName]
    if not nextState then
        error("Error: State '" .. stateName .. "' does not exist!")
    end

    self.transitioning = true
    self.previousState = self.currentState
    self.currentState = nextState

    if self.previousState and self.previousState.onExit then
        self.previousState:onExit(transitionData)
    end

    if self.currentState and self.currentState.onEnter then
        print("Calling onEnter for state:", stateName) 
        self.currentState:onEnter(transitionData)
    else
        print("No onEnter for state:", stateName) 
    end

    self:performTransition(function()
        self.transitioning = false
        if self.transitionCallback then
            self.transitionCallback()
        end
    end)
end

function StateManager:setTransitionCallback(callback)
    self.transitionCallback = callback
end

function StateManager:resetState(stateName)
    local state = self.states[stateName]
    if not state then
        error("Error: State '" .. stateName .. "' does not exist!")
    end
    if state.reset then
        state:reset()
    end
end

function StateManager:update()
    if self.transitioning then
        return
    end
    if self.currentState and self.currentState.update then
        self.currentState:update()
    end
end

function StateManager:draw()
    if self.transitioning then
        return
    end
    if self.currentState and self.currentState.draw then
        self.currentState:draw()
    end
end

function StateManager:performTransition(onComplete)

    if onComplete then
        onComplete()
    end
end

function StateManager:pauseCurrentState()
    if self.currentState and self.currentState.pause then
        self.currentState:pause()
    end
end

function StateManager:resumeCurrentState()
    if self.currentState and self.currentState.resume then
        self.currentState:resume()
    end
end

function StateManager:isTransitioning()
    return self.transitioning
end

function StateManager:debugPrintStates()
    print("Registered States:")
    for name, _ in pairs(self.states) do
        print("- " .. name)
    end
end

return StateManager
