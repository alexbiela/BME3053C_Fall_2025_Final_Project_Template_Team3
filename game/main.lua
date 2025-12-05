-- main.lua
local words = require("words")

-- Game state
local mode = "welcome"          -- "welcome", "choose", or "play"
local categoryInput = ""        
local chosenCategory = nil      

local targetWord = nil          
local currentGuess = {"", "", "", "", ""}
local currentPosition = 1
local message = ""

-- Helper: pick random word from one of the three categories
local function pickRandomWordFromCategory(categoryName)
    local bank = nil

    if categoryName == "physiology" then
        bank = words.physiology_words
    elseif categoryName == "devices" then
        bank = words.device_words
    elseif categoryName == "signals" then
        bank = words.signal_words
    end

    if bank == nil then
        return nil
    end

    local idx = math.random(1, #bank)
    return bank[idx]
end

local function resetGuessRow()
    currentGuess = {"", "", "", "", ""}
    currentPosition = 1
end

function love.load()
    love.window.setTitle("BioWordle - BME Word Game")
    love.graphics.setBackgroundColor(0.1, 0.1, 0.12)

    math.randomseed(os.time())
end

function love.textinput(t)
    t = t:lower()

    if mode == "choose" then
        if t:match("%a") then
            categoryInput = categoryInput .. t
        end

    elseif mode == "play" then
        t = t:upper()
        if t:match("%a") and currentPosition <= 5 then
            currentGuess[currentPosition] = t
            currentPosition = currentPosition + 1
        end
    end
end

function love.keypressed(key)

    ----------------------------------------------------------------
    -- WELCOME SCREEN
    ----------------------------------------------------------------
    if mode == "welcome" then
        -- Any of these keys starts the game
        if key == "return" or key == "kpenter" or key == "space" then
            mode = "choose"
            message = "Type a category and press Enter."
        end
        return
    end

    ----------------------------------------------------------------
    -- CATEGORY SELECTION SCREEN
    ----------------------------------------------------------------
    if mode == "choose" then
        if key == "backspace" then
            if #categoryInput > 0 then
                categoryInput = categoryInput:sub(1, #categoryInput - 1)
            end

        elseif key == "return" or key == "kpenter" then
            local input = categoryInput:lower()

            if input:find("phys") == 1 then
                chosenCategory = "physiology"
            elseif input:find("dev") == 1 then
                chosenCategory = "devices"
            elseif input:find("sig") == 1 then
                chosenCategory = "signals"
            else
                message = "Category not recognized. Use: physiology, devices, signals."
                return
            end

            targetWord = pickRandomWordFromCategory(chosenCategory)
            targetWord = targetWord:upper()

            resetGuessRow()
            categoryInput = ""
            mode = "play"
            message = "Category: " .. chosenCategory .. " | Guess the 5-letter word!"
        end

        return
    end

    ----------------------------------------------------------------
    -- GAMEPLAY SCREEN
    ----------------------------------------------------------------
    if mode == "play" then
        if key == "backspace" then
            if currentPosition > 1 then
                currentPosition = currentPosition - 1
                currentGuess[currentPosition] = ""
            end

        elseif key == "return" or key == "kpenter" then
            local guess = table.concat(currentGuess)
            message = "You guessed: " .. guess .. " (checking logic coming soon!)"
        end
    end
end

function love.draw()
    love.graphics.setColor(1, 1, 1)

    ----------------------------------------------------------------
    -- WELCOME SCREEN
    ----------------------------------------------------------------
    if mode == "welcome" then
        love.graphics.print("Welcome to BioWordle!", 40, 50)
        love.graphics.print("An educational biomedical Wordle game.", 40, 80)

        love.graphics.print("Press Enter or Space to begin.", 40, 130)
        return
    end

    ----------------------------------------------------------------
    -- CATEGORY SELECT SCREEN
    ----------------------------------------------------------------
    if mode == "choose" then
        love.graphics.print("Choose a Category", 40, 30)

        love.graphics.print("Available categories:", 40, 70)
        love.graphics.print("  • physiology", 60, 90)
        love.graphics.print("  • devices",     60, 110)
        love.graphics.print("  • signals",     60, 130)

        love.graphics.print("Type a category and press Enter:", 40, 170)
        love.graphics.print("> " .. categoryInput, 40, 200)

        if message ~= "" then
            love.graphics.print(message, 40, 240)
        end
        return
    end

    ----------------------------------------------------------------
    -- GAMEPLAY SCREEN
    ----------------------------------------------------------------
    if mode == "play" then
        love.graphics.print("BioWordle - Guess the Word", 40, 30)
        love.graphics.print("Category: " .. chosenCategory, 40, 60)

        if message ~= "" then
            love.graphics.print(message, 40, 100)
        end

        -- Draw 5 boxes
        local x = 40
        local y = 150
        local size = 60
        local spacing = 10

        for i = 1, 5 do
            love.graphics.setColor(0.3, 0.3, 0.35)
            love.graphics.rectangle("fill", x, y, size, size, 6, 6)
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("line", x, y, size, size, 6, 6)

            local letter = currentGuess[i]
            if letter ~= "" then
                local font = love.graphics.getFont()
                local tw = font:getWidth(letter)
                local th = font:getHeight()
                love.graphics.print(letter, x + (size - tw)/2, y + (size - th)/2)
            end

            x = x + size + spacing
        end
    end
end
