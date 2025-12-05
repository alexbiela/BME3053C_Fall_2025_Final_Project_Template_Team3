-- main.lua
local words = require("words")

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------
local ROWS = 6      -- number of guesses
local COLS = 5      -- letters per word

----------------------------------------------------------------
-- GAME STATE
----------------------------------------------------------------
local mode = "welcome"          -- "welcome", "choose", "play"
local categoryInput = ""
local chosenCategory = nil

local targetWord = nil          -- e.g. "HEART"
local guesses = {}              -- each row: { letters = {}, colors = {} }
local currentRow = 1
local currentCol = 1
local message = ""
local gameOver = false

----------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------

-- Pick a random word from the selected category list
local function pickRandomWordFromCategory(categoryName)
    local bank = nil

    if categoryName == "physiology" then
        bank = words.physiology_words
    elseif categoryName == "devices" then
        bank = words.device_words
    elseif categoryName == "signals" then
        bank = words.signal_words
    end

    if not bank or #bank == 0 then
        return nil
    end

    local idx = math.random(1, #bank)
    return bank[idx]
end

-- Clear the grid
local function initBoard()
    guesses = {}
    for r = 1, ROWS do
        guesses[r] = { letters = {}, colors = {} }
        for c = 1, COLS do
            guesses[r].letters[c] = ""
            guesses[r].colors[c] = "empty"
        end
    end
    currentRow = 1
    currentCol = 1
    gameOver = false
end

-- Start a new round after a category has been chosen
local function startNewRound()
    if not chosenCategory then
        mode = "choose"
        message = ""   -- we rely on static text in draw()
        return
    end

    targetWord = pickRandomWordFromCategory(chosenCategory)
    if not targetWord then
        message = "Error: no words in category."
        return
    end
    targetWord = targetWord:upper()

    initBoard()
    mode = "play"
    message = "Category: " .. chosenCategory .. " | Guess the 5-letter word!"
end

-- Apply Wordle-style coloring to the current row
local function evaluateCurrentRow()
    -- Build guess string and ensure row is full
    local guess = ""
    for c = 1, COLS do
        local ch = guesses[currentRow].letters[c]
        if ch == "" then
            message = "Not enough letters."
            return
        end
        guess = guess .. ch
    end
    guess = guess:upper()

    -- Frequency table for letters in target word
    local freq = {}
    for i = 1, COLS do
        local ch = targetWord:sub(i, i)
        freq[ch] = (freq[ch] or 0) + 1
    end

    -- First pass: mark greens and decrement counts
    for i = 1, COLS do
        local gch = guess:sub(i, i)
        local tch = targetWord:sub(i, i)
        if gch == tch then
            guesses[currentRow].colors[i] = "green"
            freq[gch] = freq[gch] - 1
        else
            guesses[currentRow].colors[i] = "gray"
        end
    end

    -- Second pass: mark yellows where letter exists elsewhere
    for i = 1, COLS do
        if guesses[currentRow].colors[i] ~= "green" then
            local gch = guess:sub(i, i)
            if freq[gch] and freq[gch] > 0 then
                guesses[currentRow].colors[i] = "yellow"
                freq[gch] = freq[gch] - 1
            end
        end
    end

    -- Win / lose logic
    if guess == targetWord then
        gameOver = true
        message = "Congratulations — you guessed the word!"
    elseif currentRow == ROWS then
        gameOver = true
        message = "Out of guesses. The word was: " .. targetWord
    else
        currentRow = currentRow + 1
        currentCol = 1
        message = ""
    end
end

----------------------------------------------------------------
-- LOVE CALLBACKS
----------------------------------------------------------------

function love.load()
    love.window.setTitle("BioWordle - BME Word Game")
    love.graphics.setBackgroundColor(0.1, 0.1, 0.12)
    math.randomseed(os.time())
end

function love.textinput(t)
    if mode == "choose" then
        -- typing category name
        t = t:lower()
        if t:match("%a") then
            categoryInput = categoryInput .. t
        end

    elseif mode == "play" and not gameOver then
        -- typing letters for guesses
        t = t:upper()
        if t:match("%a") and #t == 1 and currentCol <= COLS then
            guesses[currentRow].letters[currentCol] = t
            currentCol = currentCol + 1
        end
    end
end

function love.keypressed(key)
    ----------------------------------------------------------------
    -- WELCOME SCREEN
    ----------------------------------------------------------------
    if mode == "welcome" then
        if key == "return" or key == "kpenter" or key == "space" then
            mode = "choose"
            message = ""   -- no duplicate instructions
        end
        return
    end

    ----------------------------------------------------------------
    -- CATEGORY SELECT SCREEN
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

            categoryInput = ""
            startNewRound()
        end

        return
    end

    ----------------------------------------------------------------
    -- GAMEPLAY SCREEN
    ----------------------------------------------------------------
    if mode == "play" then
        -- AFTER GAME OVER:
        --  Enter / Space -> back to welcome to choose a new category
        if gameOver then
            if key == "return" or key == "kpenter" or key == "space" then
                mode = "welcome"
                message = ""
                chosenCategory = nil
            end
            return
        end

        -- DURING GAMEPLAY
        if key == "backspace" then
            if currentCol > 1 then
                currentCol = currentCol - 1
                guesses[currentRow].letters[currentCol] = ""
            end

        elseif key == "return" or key == "kpenter" then
            evaluateCurrentRow()
        end
    end
end

----------------------------------------------------------------
-- DRAWING HELPERS
----------------------------------------------------------------

local function drawCell(x, y, size, letter, colorState)
    local r, g, b = 0.2, 0.2, 0.25 -- default empty tile color

    if colorState == "green" then
        r, g, b = 0.2, 0.6, 0.2
    elseif colorState == "yellow" then
        r, g, b = 0.85, 0.75, 0.2
    elseif colorState == "gray" then
        r, g, b = 0.3, 0.3, 0.35
    end

    love.graphics.setColor(r, g, b)
    love.graphics.rectangle("fill", x, y, size, size, 6, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", x, y, size, size, 6, 6)

    if letter ~= "" then
        local font = love.graphics.getFont()
        local tw = font:getWidth(letter)
        local th = font:getHeight()
        love.graphics.print(letter, x + (size - tw) / 2, y + (size - th) / 2)
    end
end

----------------------------------------------------------------
-- LOVE.DRAW
----------------------------------------------------------------

function love.draw()
    love.graphics.setColor(1, 1, 1)

    ----------------------------------------------------------------
    -- WELCOME
    ----------------------------------------------------------------
    if mode == "welcome" then
        love.graphics.print("Welcome to BioWordle!", 40, 60)
        love.graphics.print("An educational biomedical Wordle game.", 40, 90)
        love.graphics.print("Press Enter or Space to begin.", 40, 130)
        return
    end

    ----------------------------------------------------------------
    -- CATEGORY CHOICE
    ----------------------------------------------------------------
    if mode == "choose" then
        love.graphics.print("Choose a Category", 40, 30)

        love.graphics.print("Available categories:", 40, 70)
        love.graphics.print("  • physiology", 60, 90)
        love.graphics.print("  • devices",     60, 110)
        love.graphics.print("  • signals",     60, 130)

        love.graphics.print("Type a category and press Enter:", 40, 170)
        love.graphics.print("> " .. categoryInput, 40, 200)

        -- Only show message for errors / extra info (no duplicate instructions)
        if message ~= "" then
            love.graphics.print(message, 40, 240)
        end
        return
    end

    ----------------------------------------------------------------
    -- GAMEPLAY
    ----------------------------------------------------------------
    if mode == "play" then
        love.graphics.print("BioWordle - BME Word Game", 40, 20)
        love.graphics.print("Category: " .. (chosenCategory or "?"), 40, 45)

        if not gameOver then
            love.graphics.print("Type letters, Backspace to erase, Enter to submit.", 40, 70)
        else
            love.graphics.print("Press Enter/Space to return to the welcome screen.", 40, 70)
        end

        if message ~= "" then
            love.graphics.print(message, 40, 100)
        end

        local startX = 40
        local startY = 150
        local size = 55
        local spacing = 10

        for r = 1, ROWS do
            for c = 1, COLS do
                local x = startX + (c - 1) * (size + spacing)
                local y = startY + (r - 1) * (size + spacing)
                local letter = guesses[r].letters and guesses[r].letters[c] or ""
                local colorState = guesses[r].colors and guesses[r].colors[c] or "empty"
                drawCell(x, y, size, letter or "", colorState)
            end
        end
    end
end
