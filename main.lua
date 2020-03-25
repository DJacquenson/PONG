-- push is a library that will allow us to draw our game at a virtual
Class = require 'Class'

push = require 'push'

require 'Ball'
require 'Paddle'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243
 

PADDLE_SPEED = 200

function love.load()
    
    -- set LOVE's default filter to "nearest-neighbor", which essentially
    love.graphics.setDefaultFilter('nearest', 'nearest')

    love.window.setTitle('Pong it is my game' )

    -- "Seed" the RNG so that calls to random are always random
    -- use the current time, since that will vary on startup every time
    math.randomseed(os.time())


    -- more "retro-looking" font object we can use for any text
    smallFont = love.graphics.newFont('font.ttf', 8)

    largeFont = love.graphics.newFont('font.ttf', 16)
        
    -- larger font for drawing the score on the sceen 
    scoreFont = love.graphics.newFont('font.ttf', 32)

    
    -- set LOVE's active font to the smallFont object
    love.graphics.setFont(smallFont)

    sounds = {
        ['paddle_hit'] = love.audio.newSource('paddle_hit.wav', 'static'),
        ['point_scored'] = love.audio.newSource('point_scored.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('wall_hit.wav', 'static')
    }

    -- initialize window width virtual resolution
   push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
       fullscreen = false,
       resizable = true,
       vsync = true
   })

   -- initialize score variable, used for rendering on the screen and keeping
   -- track of the winner
   
    player1Score = 0
    player2Score = 0

    servingPlayer = 1 

    winningPlayer = 0

    -- initialize our player paddles; make then global so that they can be
    -- detected by other functions and modules
    player1 = Paddle(10, 30, 5, 20)
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)

    -- place a ball in the middle of the screen
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 5, 5)
 
    if  servingPlayer == 1 then
        ball.dx = 100
    else 
        ball.dx = -100 
    end

    -- game state variable used to transition between different parts of the game
    gameState = 'start'

end

function love.resize(w, h)
    push:resize(w, h)
end


function love.update(dt)

    if gameState  == 'play' then
        
        if ball.x < 0  then
            player2Score = player2Score + 1
            servingPlayer = 1
            ball:reset()
            ball.dx = 100
            gameState = 'serve'
        end

        if ball.x > VIRTUAL_WIDTH  then
            player1Score = player1Score  + 1
            servingPlayer = 2
            ball:reset()
            ball.dx = -100
            gameState = 'serve'

        end

        -- detect ball collision width paddles, reversing dx if true and 
        -- slighty increasing it, then altering the dy based on the position of collision 
        if ball:collides(player1) then
            -- deflect ball to the right
            ball.dx =  -ball.dx * 1.03
            ball.x = player1.x + 5

            sounds['paddle_hit']:play()

            -- keep velocity going in the same direction, but randomize it
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
        end

        if ball:collides(player2) then
            -- deflect ball to the left
            ball.dx =  -ball.dx * 1.03
            ball.x = player2.x - 4

            sounds['paddle_hit']:play()

             -- keep velocity going in the same direction, but randomize it
             if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
        end

        -- detect upper and lower screen boundary collision and reverse if collided 
        if ball.y <= 0 then
            -- deflect the ball down 
            ball.y = 0
            ball.dy = -ball.dy

            sounds['wall_hit']:play()
        end

        -- -4 to account for the ball's size

        if ball.y >= VIRTUAL_HEIGHT - 4 then
            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = -ball.dy

            sounds['wall_hit']:play()
        end

        -- if we reach the left or right edge of the screen,
        -- go back to start and update the score

        if ball.x < 0 then 
            servingPlayer = 1
            player2Score = player2Score + 1

            sounds['point_scored']:play()

            if player2Score >= 10 then
                gameState = 'victory'
                winningPlayer = 2
            else
                gameState = 'serve'
                ball:reset()
            end
        end

    
        if ball.x > VIRTUAL_WIDTH then 
            servingPlayer = 2
            player1Score = player1Score + 1
            
            sounds['point_scored']:play()

            if player1Score == 10 then
                gameState = 'done'
                winningPlayer = 1
            else    
                gameState = 'serve'
                ball:reset()
            end
        end
        
        -- player 1 movement
        if love.keyboard.isDown('left') then
            player1.dy = -PADDLE_SPEED

        elseif love.keyboard.isDown('right') then
            player1.dy = PADDLE_SPEED

        else
            player1.dy = 0
        end

        -- player 2 movement
        if love.keyboard.isDown('up') then
            player2.dy = -PADDLE_SPEED
        elseif love.keyboard.isDown('down') then
            player2.dy = PADDLE_SPEED
        else
            player2.dy = 0

        end

        -- update our ball based on its DX and DY only if we're in play state;
        -- scale the velocity by dt so movement is framerate-independent

        if gameState == 'play' then
            ball:update(dt)
        end

        player1:update(dt)
        player2:update(dt)
    end

end
--[[
    keyboard handling, called by LOVE each frame;
    passes in the key we pressed so we can access
]]
function love.keypressed(key)

    -- keys can be accessed by string name
    if key == 'escape' then
        -- function LOVE gives us to terminate application 
        love.event.quit()


    -- if we press enter during the start state of the game, we'll go into play mode
    -- during play mode, the ball will move in a random direction        
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'serve'

        elseif gameState == 'victory' then
            gameState = 'start'
            player1Score = 0 
            player2Score = 0 

        elseif  gameState == 'serve' then
            gameState = 'play'

        end
    end
end

--[[
    called after update by LOVE, used to draw anything to the screen,
    updated or otherwise. 
]]
function love.draw()

    -- begin rendering at virtual resolution
    push:apply('start') 

    -- Clear the screen width a specific color; in this case, a color similar
    -- to some versions of the original Pong
    love.graphics.clear(40 / 255, 45 / 255, 52 / 255, 255 / 255)

    -- draw different things based on the state of the game
    love.graphics.setFont(smallFont)

    if gameState == 'start' then
        love.graphics.setFont(smallFont) 
        love.graphics.printf("Welcome to Pong!", 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf("Press enter to begin!", 0, 20, VIRTUAL_WIDTH, 'center')

    elseif  gameState == 'serve' then
        love.graphics.setFont(smallFont)
        love.graphics.printf("Player" .. tostring(servingPlayer) .. "'s serve!",
         0, 20, VIRTUAL_WIDTH, 'center')
        love.graphics.printf("Press Enter to serve", 0, 32, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'victory' then
        -- draw a victory message 
        love.graphics.setFont(victoryFont)
        love.graphics.printf('Player' .. tostring(winningPlayer) .. " wins!", 
         0, 20, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf("Press Enter to serve", 0, 42, VIRTUAL_WIDTH, 'center')

    elseif gameState == 'play' then
        -- no UI messages to display in polay

    end
    -- draw score on the left and right center of the screen
    -- need to switch font to draw before actually printing

    love.graphics.setFont(scoreFont)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50,
     VIRTUAL_HEIGHT / 3)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 30, 
    VIRTUAL_HEIGHT / 3)
   
    --render paddles, now using their class's render method 
    player1:render()
    player2:render()

    --render ball using its class's render method
    ball:render()

    -- new function just to demonstrate how to see FPS in LOVE2D
    displayFPS()
         
    -- end rendering at virtual resolution
    push:apply('end')
end 

--[[
    Renders the current FPS
]]

function displayFPS()
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.setFont(smallFont)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 40, 20)
    love.graphics.setColor(1, 1, 1, 1)
end