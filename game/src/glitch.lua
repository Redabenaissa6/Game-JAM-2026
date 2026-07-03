local Glitch = {}

function Glitch.new()
    return {
        timer = 0,
        nextSwitch = 5,
        active = false,
        warning = false,
        warningTimer = 0,
        warningDuration = 1.1,
        phase = "normal",
        pendingPhase = nil,
        inputSwap = false,
        speedMult = 1,
        paletteShift = false,
    }
end

function Glitch.update(state, dt)
    state.timer = state.timer + dt

    if state.warning then
        state.warningTimer = state.warningTimer + dt

        if state.warningTimer >= state.warningDuration then
            state.warning = false
            state.warningTimer = 0
            state.active = true
            state.phase = state.pendingPhase or "inverted"
            state.pendingPhase = nil
            state.inputSwap = state.phase == "inverted"
            state.speedMult = state.phase == "accelerated" and 1.6 or 1
            state.paletteShift = state.phase == "desaturated"
            state.nextSwitch = love.math.random(4, 7)
            state.timer = 0
        end

        return
    end

    if state.timer >= state.nextSwitch then
        state.timer = 0
        if state.active then
            state.active = false
            state.phase = "normal"
            state.inputSwap = false
            state.speedMult = 1
            state.paletteShift = false
            state.nextSwitch = love.math.random(6, 10)
        else
            state.warning = true
            state.warningTimer = 0
            state.pendingPhase = ({"inverted", "accelerated", "desaturated"})[love.math.random(3)]
        end
    end
end

function Glitch.transformInput(state, dx, dy)
    if not state.inputSwap then
        return dx, dy
    end

    return -dx, -dy
end

function Glitch.canvasTint(state)
    if state.warning then
        local pulse = 0.5 + math.sin(state.warningTimer * 18) * 0.5
        return 1.0, 0.75 + pulse * 0.15, 0.2 + pulse * 0.1, 1
    end

    if state.paletteShift then
        return 0.8, 0.95, 1.0, 1
    end

    if state.active then
        return 1.0, 0.82, 1.0, 1
    end

    return 1, 1, 1, 1
end

function Glitch.describe(state)
    if state.warning then
        return "glitch: warning..."
    end

    if state.phase == "inverted" then
        return "glitch: controls inverted"
    end

    if state.phase == "accelerated" then
        return "glitch: movement boosted"
    end

    if state.phase == "desaturated" then
        return "glitch: palette shifted"
    end

    return "glitch: stable"
end

return Glitch