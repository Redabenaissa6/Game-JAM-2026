local Level = {}

local function createGrid(width, height)
    local grid = {}

    for row = 1, height do
        grid[row] = {}
        for col = 1, width do
            grid[row][col] = "."
        end
    end

    return grid
end

local function setCell(grid, col, row, value)
    if grid[row] and grid[row][col] ~= nil then
        grid[row][col] = value
    end
end

local function fillRect(grid, left, top, right, bottom, value)
    for row = top, bottom do
        for col = left, right do
            setCell(grid, col, row, value)
        end
    end
end

local function addBorder(grid, width, height)
    fillRect(grid, 1, 1, width, 1, "#")
    fillRect(grid, 1, height, width, height, "#")
    fillRect(grid, 1, 1, 1, height, "#")
    fillRect(grid, width, 1, width, height, "#")
end

local function finalizeMap(grid)
    local map = {}

    for row = 1, #grid do
        map[row] = table.concat(grid[row])
    end

    return map
end

local function placeCoins(coins, remainingCoins, positions)
    for _, position in ipairs(positions) do
        coins[position.row] = coins[position.row] or {}
        coins[position.row][position.col] = true
        remainingCoins = remainingCoins + 1
    end

    return remainingCoins
end

local function findHorizontalBounds(map, row, col)
    local width = #map[row]
    local leftCol = col
    local rightCol = col

    while leftCol > 1 and map[row]:sub(leftCol - 1, leftCol - 1) ~= "#" do
        leftCol = leftCol - 1
    end

    while rightCol < width and map[row]:sub(rightCol + 1, rightCol + 1) ~= "#" do
        rightCol = rightCol + 1
    end

    return leftCol, rightCol
end

local function rectsOverlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and bx < ax + aw and ay < by + bh and by < ay + ah
end

local function buildVariantThree()
    -- Layout provided by the user (1=wall, 0=empty, C=coin, P=player, E=end/door, B=enemy)
    local raw = {
        "1111111111111111111111111111111111111",
        "1C0000E0000P0000C000C1010000000000001",
        "1C01111111111000C000C0000000000000001",
        "1CB00000CCC010011110C0000000000000001",
        "1C00000C00001000C010C0000000000000001",
        "1CC0000000000000000000000000000000001",
        "1C00C01000CC0000C001C1001111111111111",
        "1CC0000001111001C000C0001",
        "1C000000000010111110C0001",
        "1C00010000001000C010C0011",
        "1111111111111111111111111",
    }

    local map = {}
    local startCol, startRow, doorCol, doorRow

    for r = 1, #raw do
        local line = {}
        for c = 1, #raw[r] do
            local ch = raw[r]:sub(c, c)
            local out = ch

            if ch == "1" then
                out = "#"
            elseif ch == "0" then
                out = "."
            elseif ch == "P" then
                out = "."
                startCol = c
                startRow = r
            elseif ch == "E" then
                -- user's E is the door; convert to D
                out = "D"
                doorCol = c
                doorRow = r
            elseif ch == "B" then
                -- user's B is enemy start; convert to E (enemy)
                out = "E"
            end

            line[c] = out
        end
        map[r] = table.concat(line)
    end

    return {
        map = map,
        startCol = startCol or 2,
        startRow = startRow or 2,
        doorCol = doorCol,
        doorRow = doorRow,
    }
end

local function buildVariant()
    return buildVariantThree()
end

function Level.new(tileSize, startCol, startRow)
    local data = buildVariant()
    local map = data.map
    local coins = {}
    local remainingCoins = 0
    local enemies = {}

    for row = 1, #map do
        coins[row] = {}
        for col = 1, #map[row] do
            local cell = map[row]:sub(col, col)

            if cell == "C" then
                coins[row][col] = true
                remainingCoins = remainingCoins + 1
            elseif cell == "E" then
                local leftCol, rightCol = findHorizontalBounds(map, row, col)
                local leftX = (leftCol - 1) * tileSize
                local rightX = (rightCol - 1) * tileSize
                local baseY = (row - 1) * tileSize
                enemies[#enemies + 1] = {
                    col = col,
                    row = row,
                    flashTimer = math.random() * 6,
                    animTimer = math.random() * 2,
                    moveTimer = math.random() * 2,
                    moveSpeed = tileSize * 1.8,
                    leftX = leftX,
                    rightX = rightX,
                    x = leftX + math.random() * math.max(1, rightX - leftX),
                    y = baseY,
                    width = tileSize * 0.9,
                    height = tileSize * 0.9,
                    direction = math.random() < 0.5 and -1 or 1,
                }
            end
        end
    end

    return setmetatable({
        tileSize = tileSize,
        map = map,
        width = #map[1],
        height = #map,
        wallImage = nil,
        doorImage = nil,
        batFrames = {},
        coins = coins,
        remainingCoins = remainingCoins,
        enemies = enemies,
        startCol = data.startCol or startCol or 2,
        startRow = data.startRow or startRow or 2,
        doorCol = data.doorCol,
        doorRow = data.doorRow,
    }, {__index = Level})
end

function Level.loadAssets(level)
    local pngPath = "assets/wall-0.png"
    local webpPath = "assets/wall-0.webp"
    local doorPath = "assets/textures/Door.png"
    local bat1Path = "assets/textures/bat1.png"
    local bat2Path = "assets/textures/bat2.png"

    if love.filesystem.getInfo(pngPath) then
        level.wallImage = love.graphics.newImage(pngPath)
    else
        if love.filesystem.getInfo(webpPath) then
            level.wallImage = love.graphics.newImage(webpPath)
        else
            level.wallImage = nil
        end
    end

    if love.filesystem.getInfo(doorPath) then
        level.doorImage = love.graphics.newImage(doorPath)
    else
        level.doorImage = nil
    end

    level.batFrames = {}
    if love.filesystem.getInfo(bat1Path) then
        level.batFrames[#level.batFrames + 1] = love.graphics.newImage(bat1Path)
    end
    if love.filesystem.getInfo(bat2Path) then
        level.batFrames[#level.batFrames + 1] = love.graphics.newImage(bat2Path)
    end
end

function Level:isDoorCell(col, row)
    return self.doorCol == col and self.doorRow == row
end

function Level.hasEnemy(level, col, row)
    for _, enemy in ipairs(level.enemies) do
        local enemyCol = math.floor((enemy.x + enemy.width * 0.5) / level.tileSize) + 1
        local enemyRow = math.floor((enemy.y + enemy.height * 0.5) / level.tileSize) + 1

        if enemyCol == col and enemyRow == row then
            return true
        end
    end

    return false
end

function Level.hasEnemyAt(level, px, py, width, height)
    for _, enemy in ipairs(level.enemies) do
        if rectsOverlap(px, py, width, height, enemy.x, enemy.y, enemy.width, enemy.height) then
            return true
        end
    end

    return false
end

function Level:isPassableCell(col, row)
    local line = self.map[row]
    if not line then
        return false
    end

    local cell = line:sub(col, col)
    if cell == "#" then
        return false
    end

    return true
end

function Level:isWallCell(col, row)
    return not self:isPassableCell(col, row)
end

function Level:isBlocked(px, py)
    local col = math.floor(px / self.tileSize) + 1
    local row = math.floor(py / self.tileSize) + 1
    return self:isWallCell(col, row)
end

function Level.hasCoin(level, col, row)
    return level.coins[row] and level.coins[row][col] or false
end

function Level.collectCoin(level, col, row)
    if not Level.hasCoin(level, col, row) then
        return false
    end

    level.coins[row][col] = nil
    level.remainingCoins = math.max(0, level.remainingCoins - 1)
    return true
end

function Level.collectPathCoins(level, startCol, startRow, endCol, endRow)
    if startCol == endCol then
        local step = endRow >= startRow and 1 or -1
        for row = startRow, endRow, step do
            Level.collectCoin(level, startCol, row)
        end
        return
    end

    if startRow == endRow then
        local step = endCol >= startCol and 1 or -1
        for col = startCol, endCol, step do
            Level.collectCoin(level, col, startRow)
        end
    end
end

function Level.update(level, dt)
    for _, enemy in ipairs(level.enemies) do
        enemy.flashTimer = enemy.flashTimer + dt
        enemy.animTimer = enemy.animTimer + dt

        enemy.x = enemy.x + enemy.direction * enemy.moveSpeed * dt
        if enemy.x <= enemy.leftX then
            enemy.x = enemy.leftX
            enemy.direction = 1
        elseif enemy.x >= enemy.rightX then
            enemy.x = enemy.rightX
            enemy.direction = -1
        end

        enemy.moveTimer = enemy.moveTimer + dt
    end
end

function Level.draw(level, colors, glitchState)
    local tileSize = level.tileSize
    local tint = {colors.wall[1], colors.wall[2], colors.wall[3], colors.wall[4]}
    local warningPulse = 0

    if glitchState.warning then
        warningPulse = 0.5 + math.sin(glitchState.warningTimer * 18) * 0.5
    end

    if glitchState.paletteShift then
        tint = {0.65, 0.95, 1.0, 1}
    elseif glitchState.active then
        tint = {1, 0.8, 1, 1}
    end

    for row = 1, level.height do
        for col = 1, level.width do
            local x = (col - 1) * tileSize
            local y = (row - 1) * tileSize
            local drawX = x
            local drawY = y

            if glitchState.warning then
                local waveX = math.sin((row + glitchState.warningTimer * 10) * 0.8) * 3 * warningPulse
                local waveY = math.cos((col + glitchState.warningTimer * 12) * 0.8) * 3 * warningPulse
                drawX = x + waveX
                drawY = y + waveY
            end

            if level:isWallCell(col, row) then
                love.graphics.setColor(tint)
                if level.wallImage then
                    love.graphics.draw(level.wallImage, drawX, drawY, 0, tileSize / level.wallImage:getWidth(), tileSize / level.wallImage:getHeight())
                else
                    love.graphics.rectangle("fill", drawX, drawY, tileSize, tileSize)
                end
            else
                love.graphics.setColor(colors.floor)
                love.graphics.rectangle("fill", drawX, drawY, tileSize, tileSize)

                if level:isDoorCell(col, row) then
                    local doorLocked = level.remainingCoins > 0
                    if level.doorImage then
                        local tintAlpha = doorLocked and 0.75 or 1
                        love.graphics.setColor(1, 1, 1, tintAlpha)
                        love.graphics.draw(level.doorImage, drawX, drawY, 0, tileSize / level.doorImage:getWidth(), tileSize / level.doorImage:getHeight())
                    else
                        local doorInset = tileSize * 0.14

                        if doorLocked then
                            love.graphics.setColor(0.38, 0.16, 0.45, 1)
                            love.graphics.rectangle("fill", drawX + doorInset, drawY + doorInset, tileSize - doorInset * 2, tileSize - doorInset * 2, 5, 5)
                            love.graphics.setColor(1.0, 0.82, 0.2, 1)
                            love.graphics.rectangle("fill", drawX + tileSize * 0.44, drawY + tileSize * 0.34, tileSize * 0.12, tileSize * 0.22, 3, 3)
                        else
                            love.graphics.setColor(0.2, 0.8, 0.4, 1)
                            love.graphics.rectangle("fill", drawX + doorInset, drawY + doorInset, tileSize - doorInset * 2, tileSize - doorInset * 2, 5, 5)
                            love.graphics.setColor(0.92, 1.0, 0.95, 0.85)
                            love.graphics.rectangle("line", drawX + doorInset, drawY + doorInset, tileSize - doorInset * 2, tileSize - doorInset * 2, 5, 5)
                        end
                    end
                end

                if Level.hasCoin(level, col, row) then
                    local coinPulse = 0.5 + math.sin((row + col + (glitchState.timer or 0) * 8) * 0.9) * 0.15
                    local coinSize = tileSize * 0.18 + coinPulse * 2
                    local centerX = drawX + tileSize * 0.5
                    local centerY = drawY + tileSize * 0.5

                    love.graphics.setColor(1.0, 0.92, 0.2, 1)
                    love.graphics.circle("fill", centerX, centerY, coinSize)
                    love.graphics.setColor(1.0, 1.0, 0.75, 0.95)
                    love.graphics.circle("fill", centerX - coinSize * 0.3, centerY - coinSize * 0.3, math.max(1.5, coinSize * 0.25))
                end

            end
        end
    end

    love.graphics.setColor(colors.grid)
    for row = 0, level.height do
        local y = row * tileSize
        if glitchState.warning then
            y = y + math.sin((row + glitchState.warningTimer * 8) * 1.5) * 1.5 * warningPulse
        end
        love.graphics.line(0, y, level.width * tileSize, y)
    end
    for col = 0, level.width do
        local x = col * tileSize
        if glitchState.warning then
            x = x + math.cos((col + glitchState.warningTimer * 8) * 1.5) * 1.5 * warningPulse
        end
        love.graphics.line(x, 0, x, level.height * tileSize)
    end
end

function Level.drawEnemies(level, colors, glitchState)
    local tileSize = level.tileSize

    for _, enemy in ipairs(level.enemies) do
        local row = math.floor((enemy.y + enemy.height * 0.5) / tileSize) + 1
        local col = math.floor((enemy.x + enemy.width * 0.5) / tileSize) + 1
        local bob = 0.5 + math.sin((row + col + (glitchState.timer or 0) * 9) * 1.2) * 0.08
        local frameCount = #level.batFrames
        local frameIndex = frameCount > 0 and (math.floor(enemy.animTimer * 4) % frameCount) + 1 or 0
        local batImage = frameCount > 0 and level.batFrames[frameIndex] or nil
        local batCenterX = enemy.x + enemy.width * 0.5
        local batCenterY = enemy.y + enemy.height * 0.5 + bob

        if batImage then
            local spriteWidth = batImage:getWidth()
            local spriteHeight = batImage:getHeight()
            local scale = (tileSize * 0.9) / math.max(spriteWidth, spriteHeight)
            local scaleX = enemy.direction > 0 and -scale or scale
            local scaleY = scale

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(batImage, batCenterX, batCenterY, 0, scaleX, scaleY, spriteWidth * 0.5, spriteHeight * 0.5)
        else
            local pulse = 0.5 + math.sin((row + col + (glitchState.timer or 0) * 9) * 1.2) * 0.18
            local enemySize = tileSize * 0.38 + pulse * 2

            love.graphics.setColor(0.95, 0.2, 0.28, 1)
            love.graphics.circle("fill", batCenterX, batCenterY, enemySize)
            love.graphics.setColor(1.0, 0.82, 0.82, 0.9)
            love.graphics.circle("fill", batCenterX - enemySize * 0.28, batCenterY - enemySize * 0.24, math.max(1.5, enemySize * 0.12))
            love.graphics.circle("fill", batCenterX + enemySize * 0.28, batCenterY - enemySize * 0.24, math.max(1.5, enemySize * 0.12))
        end
    end
end

return Level