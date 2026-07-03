local Glitch = require("src.glitch")
local Level = require("src.level")
local Player = require("src.player")

local Game = {}

function Game.load()
    math.randomseed(os.time())

    Game.tileSize = 40
    Game.level = Level.new(Game.tileSize)
    Level.loadAssets(Game.level)
    Game.glitch = Glitch.new()
    Game.colors = {
        background = {0.06, 0.06, 0.09},
        floor = {0, 0, 0},
        wall = {0.85, 0.15, 0.95, 1},
        grid = {0, 0, 0},
        coin = {1.0, 0.92, 0.2, 1},
        player = {1.0, 0.92, 0.18, 1},
        playerGlow = {1.0, 0.82, 0.12},
        trail = {1.0, 1, 0.2},
        text = {0.9, 0.92, 1, 1},
    }

    local startCol = Game.level.startCol or 2
    local startRow = Game.level.startRow or 2
    local startX = (startCol - 1) * Game.tileSize
    local startY = (startRow - 1) * Game.tileSize
    Game.player = Player.new(startX, startY, Game.tileSize)
    Player.loadAssets(Game.player)
    Game.camera = {x = 0, y = 0}
    Game.moveBuffer = {dx = 0, dy = 0}
    Game.gameOver = false
    Game.win = false
    Game.endTimer = 0
    Game.updateCamera()
end

function Game.updateCamera()
    local viewWidth = love.graphics.getWidth()
    local viewHeight = love.graphics.getHeight()
    local mapWidth = Game.level.width * Game.level.tileSize
    local mapHeight = Game.level.height * Game.level.tileSize

    Game.camera.x = Game.player.x + Game.level.tileSize * 0.5 - viewWidth * 0.5
    Game.camera.y = Game.player.y + Game.level.tileSize * 0.5 - viewHeight * 0.5

    if Game.camera.x < 0 then
        Game.camera.x = 0
    end
    if Game.camera.y < 0 then
        Game.camera.y = 0
    end
    if Game.camera.x > mapWidth - viewWidth then
        Game.camera.x = math.max(0, mapWidth - viewWidth)
    end
    if Game.camera.y > mapHeight - viewHeight then
        Game.camera.y = math.max(0, mapHeight - viewHeight)
    end
end

function Game.tryBufferedMove()
    if Game.player.moving then
        return
    end

    local dx = Game.moveBuffer.dx
    local dy = Game.moveBuffer.dy
    if dx == 0 and dy == 0 then
        return
    end

    local transformedDx, transformedDy = Glitch.transformInput(Game.glitch, dx, dy)
    if Player.requestMove(Game.player, transformedDx, transformedDy, Game.level, Game.glitch) then
        Game.moveBuffer.dx = 0
        Game.moveBuffer.dy = 0
    end
end

function Game.update(dt)
    if Game.gameOver or Game.win then
        Game.endTimer = Game.endTimer + dt
        if Game.endTimer > 0 then
            love.event.quit()
        end
        return
    end

    Glitch.update(Game.glitch, dt)
    Level.update(Game.level, dt)
    Player.updateTrail(Game.player, dt)
    Player.update(Game.player, dt)

    if Game.player.justLanded and Game.player.moveStartCol and Game.player.moveStartRow and Game.player.moveTargetCol and Game.player.moveTargetRow then
        Level.collectPathCoins(
            Game.level,
            Game.player.moveStartCol,
            Game.player.moveStartRow,
            Game.player.moveTargetCol,
            Game.player.moveTargetRow
        )
        Game.player.justLanded = false
    end

    local playerCol = math.floor(Game.player.x / Game.player.tileSize) + 1
    local playerRow = math.floor(Game.player.y / Game.player.tileSize) + 1

    if Level.hasEnemy(Game.level, playerCol, playerRow) then
        Game.gameOver = true
    elseif Game.level.remainingCoins == 0 and Game.level:isDoorCell(playerCol, playerRow) then
        Game.win = true
    end

    Game.tryBufferedMove()
    Game.updateCamera()
end

function Game.draw()
    love.graphics.clear(unpack(Game.colors.background))

    local r, g, b, a = Glitch.canvasTint(Game.glitch)
    love.graphics.push()
    love.graphics.translate(-Game.camera.x, -Game.camera.y)
    if Game.glitch.warning then
        local shake = math.sin(Game.glitch.warningTimer * 40) * 2
        love.graphics.translate(shake, -shake * 0.5)
    end
    love.graphics.setColor(r, g, b, a)
    Level.draw(Game.level, Game.colors, Game.glitch)
    Player.draw(Game.player, Game.colors, Game.glitch)
    love.graphics.pop()

    love.graphics.setColor(Game.colors.text)
    love.graphics.print("Arrow keys move. Collect all C tiles to unlock D. Touch E and you lose.", 16, Game.level.height * Game.tileSize + 10)
    love.graphics.print(Glitch.describe(Game.glitch), 16, Game.level.height * Game.tileSize + 30)
    love.graphics.print("Coins left: " .. tostring(Game.level.remainingCoins), 16, Game.level.height * Game.tileSize + 50)

    if Game.gameOver then
        love.graphics.print("Enemy caught you. Press R to restart.", 16, Game.level.height * Game.tileSize + 70)
    elseif Game.win then
        love.graphics.print("Door unlocked. You escaped. Press R for a new map.", 16, Game.level.height * Game.tileSize + 70)
    end
end

function Game.keypressed(key)
    local mapping = {
        up = {dx = 0, dy = -1},
        down = {dx = 0, dy = 1},
        left = {dx = -1, dy = 0},
        right = {dx = 1, dy = 0},
    }

    if mapping[key] then
        Game.moveBuffer.dx = mapping[key].dx
        Game.moveBuffer.dy = mapping[key].dy
        Game.tryBufferedMove()
    elseif key == "r" then
        Game.load()
    end
end

return Game