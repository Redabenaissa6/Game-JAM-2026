local Player = {}

function Player.new(x, y, tileSize)
    return {
        x = x,
        y = y,
        tileSize = tileSize,
        moving = false,
        targetX = x,
        targetY = y,
        baseSpeed = 1300,
        moveSpeed = 1300,
        dirX = 0,
        dirY = 0,
        facingAngle = 0,
        facingDX = 0,
        facingDY = 1,
        sprite = nil,
        moveSound = nil,
        landSound = nil,
        trail = {},
        trailSpawnTimer = 0,
        justLanded = false,
        moveStartCol = nil,
        moveStartRow = nil,
        moveTargetCol = nil,
        moveTargetRow = nil,
        animTime = 0,
    }
end

function Player.loadAssets(player)
    local spritePath = "assets/player/Travelboy.png"
    local fallbackPath = "assets/player/Travelboy.webp"

    if love.filesystem.getInfo(spritePath) then
        player.sprite = love.graphics.newImage(spritePath)
    elseif love.filesystem.getInfo(fallbackPath) then
        player.sprite = love.graphics.newImage(fallbackPath)
    else
        player.sprite = nil
    end

    local moveSoundPath = "assets/sound/Jump_3.wav"

    if love.filesystem.getInfo(moveSoundPath) then
        player.moveSound = love.audio.newSource(moveSoundPath, "static")
    end
end

function Player.requestMove(player, dx, dy, level, glitchState)
    if player.moving or (dx == 0 and dy == 0) then
        return false
    end

    local speed = player.baseSpeed * glitchState.speedMult
    local currentCol = math.floor(player.x / player.tileSize) + 1
    local currentRow = math.floor(player.y / player.tileSize) + 1
    local targetCol = currentCol
    local targetRow = currentRow

    while true do
        local nextCol = targetCol + dx
        local nextRow = targetRow + dy

        if not level:isPassableCell(nextCol, nextRow) then
            break
        end

        targetCol = nextCol
        targetRow = nextRow
    end

    if targetCol == currentCol and targetRow == currentRow then
        return false
    end

    player.moving = true
    player.justLanded = false
    player.moveStartCol = currentCol
    player.moveStartRow = currentRow
    player.moveTargetCol = targetCol
    player.moveTargetRow = targetRow
    player.targetX = (targetCol - 1) * player.tileSize
    player.targetY = (targetRow - 1) * player.tileSize
    player.dirX = dx
    player.dirY = dy
    if dx ~= 0 then
        player.facingAngle = dx > 0 and -math.pi / 2 or math.pi / 2
        player.facingDX = dx
        player.facingDY = 0
    elseif dy ~= 0 then
        player.facingAngle = dy > 0 and 0 or math.pi
        player.facingDX = 0
        player.facingDY = dy
    end
    player.moveSpeed = speed

    if player.moveSound then
        player.moveSound:stop()
        player.moveSound:play()
    end

    return true
end

function Player.update(player, dt)
    player.animTime = player.animTime + dt

    if not player.moving then
        return
    end

    player.trailSpawnTimer = player.trailSpawnTimer + dt
    while player.trailSpawnTimer >= 0.02 do
        player.trailSpawnTimer = player.trailSpawnTimer - 0.02
        table.insert(player.trail, 1, {
            x = player.x,
            y = player.y,
            life = 0.12,
            dirX = player.dirX,
            dirY = player.dirY,
        })

        if #player.trail > 100 then
            table.remove(player.trail)
        end
    end

    local step = player.moveSpeed * dt
    local dx = player.targetX - player.x
    local dy = player.targetY - player.y
    local distance = math.sqrt(dx * dx + dy * dy)

    if step >= distance then
        player.x = player.targetX
        player.y = player.targetY
        player.moving = false
        player.justLanded = true
        player.trail = {}
        player.trailSpawnTimer = 0
        if player.landSound then
            player.landSound:stop()
            player.landSound:play()
        end
        return
    end

    player.x = player.x + player.dirX * step
    player.y = player.y + player.dirY * step
end

function Player.updateTrail(player, dt)
    for index = #player.trail, 1, -1 do
        local segment = player.trail[index]
        segment.life = segment.life - dt
        if segment.life <= 0 then
            table.remove(player.trail, index)
        end
    end
end

function Player.draw(player, colors, glitchState)
    for index, segment in ipairs(player.trail) do
        local alpha = math.max(segment.life / 0.12, 0)
        local baseR = 1.0
        local baseG = 0.97
        local baseB = 0.28

        if segment.dirY ~= 0 then
            local barWidth = math.max(2, player.tileSize * 0.08)
            local shortHeight = player.tileSize * 0.82
            local tallHeight = player.tileSize * 1.15
            local centerX = segment.x + player.tileSize * 0.5
            local centerY = segment.y + player.tileSize * 0.5 - segment.dirY * (player.tileSize * 0.18)
            local sideOffset = player.tileSize * 0.12

            love.graphics.setColor(baseR, baseG, baseB, alpha * 0.55)
            love.graphics.rectangle("fill", centerX - sideOffset - barWidth * 0.5, centerY - shortHeight * 0.5, barWidth, shortHeight, 2, 2)
            love.graphics.rectangle("fill", centerX + sideOffset - barWidth * 0.5, centerY - shortHeight * 0.5, barWidth, shortHeight, 2, 2)

            love.graphics.setColor(1.0, 1.0, 0.42, alpha * 0.85)
            love.graphics.rectangle("fill", centerX - barWidth * 0.5, centerY - tallHeight * 0.5, barWidth, tallHeight, 2, 2)
        else
            local barHeight = math.max(2, player.tileSize * 0.08)
            local shortWidth = player.tileSize * 0.82
            local tallWidth = player.tileSize * 1.15
            local centerX = segment.x + player.tileSize * 0.5 - segment.dirX * (player.tileSize * 0.18)
            local centerY = segment.y + player.tileSize * 0.5
            local sideOffset = player.tileSize * 0.12

            love.graphics.setColor(baseR, baseG, baseB, alpha * 0.55)
            love.graphics.rectangle("fill", centerX - shortWidth * 0.5, centerY - sideOffset - barHeight * 0.5, shortWidth, barHeight, 2, 2)
            love.graphics.rectangle("fill", centerX - shortWidth * 0.5, centerY + sideOffset - barHeight * 0.5, shortWidth, barHeight, 2, 2)

            love.graphics.setColor(1.0, 1.0, 0.42, alpha * 0.85)
            love.graphics.rectangle("fill", centerX - tallWidth * 0.5, centerY - barHeight * 0.5, tallWidth, barHeight, 2, 2)
        end
    end

    if player.sprite then
        local spriteWidth = player.sprite:getWidth()
        local spriteHeight = player.sprite:getHeight()
        local scale = (player.tileSize - 6) / math.max(spriteWidth, spriteHeight)
        local scaleX = scale
        local scaleY = scale
        local contactShift = player.tileSize * 0.14
        local drawX = player.x + player.tileSize * 0.5 + player.facingDX * contactShift
        local drawY = player.y + player.tileSize * 0.5 + player.facingDY * contactShift
        local glitchActive = glitchState and (glitchState.active or glitchState.warning)

        if glitchActive then
            local phase = (glitchState.warning and glitchState.warningTimer or glitchState.timer) * 28
            local jitterX = math.sin(phase) * 2.5
            local jitterY = math.cos(phase * 1.3) * 1.5
            local redOffset = math.sin(phase * 0.9) * 2.5
            local blueOffset = math.cos(phase * 1.1) * 2.5

            love.graphics.setColor(1.0, 0.3, 0.3, 0.9)
            love.graphics.draw(
                player.sprite,
                drawX + jitterX - redOffset,
                drawY + jitterY,
                player.facingAngle,
                scaleX,
                scaleY,
                spriteWidth * 0.5,
                spriteHeight * 0.5
            )

            love.graphics.setColor(0.35, 0.75, 1.0, 0.9)
            love.graphics.draw(
                player.sprite,
                drawX - jitterX + blueOffset,
                drawY - jitterY,
                player.facingAngle,
                scaleX,
                scaleY,
                spriteWidth * 0.5,
                spriteHeight * 0.5
            )

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(
                player.sprite,
                drawX + jitterX * 0.5,
                drawY + jitterY * 0.5,
                player.facingAngle,
                scaleX,
                scaleY,
                spriteWidth * 0.5,
                spriteHeight * 0.5
            )
        else
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(
                player.sprite,
                drawX,
                drawY,
                player.facingAngle,
                scaleX,
                scaleY,
                spriteWidth * 0.5,
                spriteHeight * 0.5
            )
        end
    else
        local pulse = 1 + math.sin(player.animTime * 12) * 0.035
        local size = player.tileSize - 8
        local offset = (player.tileSize - size * pulse) * 0.5

        love.graphics.setColor(0.18, 0.14, 0.02, 1)
        love.graphics.rectangle("fill", player.x + offset, player.y + offset, size * pulse, size * pulse, 8, 8)

        love.graphics.setColor(colors.player)
        love.graphics.rectangle("fill", player.x + offset + 2, player.y + offset + 2, size * pulse - 4, size * pulse - 4, 7, 7)
    end
end

return Player