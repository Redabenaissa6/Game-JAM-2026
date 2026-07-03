local Game = require("src.game")

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setTitle("Tomb Glitch Prototype")
    Game.load()
end

function love.update(dt)
    Game.update(dt)
end

function love.draw()
    Game.draw()
end

function love.keypressed(key)
    Game.keypressed(key)
end