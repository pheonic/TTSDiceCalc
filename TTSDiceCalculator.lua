DELAY_TIME = 0.1 --Increasing this number should increase performance but make the calculator slower
rolls = {}
function onObjectRandomize(object, player_color)
    local steam_name = Player[player_color].steam_name
    if rolls[steam_name] == nil then
        broadcastToAll(steam_name .. " has started rolling", {0,255,0})
        rolls[steam_name] = newPlayerRoll(steam_name)
        rolls[steam_name].start_roll(object)
    else
        rolls[steam_name].add(object)
    end
end

function newPlayerRoll(steam_name)
    local self = {
        dice = {},
        steam_name = steam_name,
    }

    local still_rolling = function()
        Timer.destroy(self.steam_name .. ":roll_timer")
        Timer.create({
            identifier = self.steam_name .. ":roll_timer",
            function_name = "finishRoll",
            parameters = { self.steam_name },
            delay = DELAY_TIME, --in seconds
        })
    end

    local add = function(object)
        still_rolling()
        self.dice[object.getGUID()] = object
    end

    local really_finished = function()
        for k, v in pairs(self.dice) do
            if not v.resting then
                return false
            end
        end
        return true
    end

    local groupDice = function()
        counts = {}
        counts[20] = {}
        total = 0
        for k, v in pairs(self.dice) do
            diceType = #v.getRotationValues()
            value = v.getValue() or 0
            counts[diceType] = counts[diceType] or {}
            table.insert(counts[diceType], value)
            if diceType != 20 then
                total = total + value
            end
        end
        return counts, total
    end

    local finishMessage = function()
        counts, total = groupDice()
        message = self.steam_name .. " has rolled "
        if #counts[20] > 0 then
            message = message .. #counts[20] .. "d20 (" .. table.concat(counts[20], ",") .. ") "
            if total > 0 then
                message = message .. "and "
            end
        end
        for k, v in pairs(counts) do
            if k != 20 and k != 0 then
                message = message .. #v .. "d" .. k .. "+"
            end
        end
        if total > 0 then
            message = message:sub( 1, string.len(message) - 1) .. "=" .. total
        end
        return message
    end

    local finish = function()
        if not really_finished() then
            still_rolling()
        else
            message = finishMessage()
            broadcastToAll(message, {0,255,0})
            self.dice = {} -- can optimize this if RAM becomes an issue
        end
    end

    return {
        add = add,
        start_roll = add,
        finish = finish,
    }
end

function finishRoll(steam_name)
    steam_name = steam_name[1]
    rolls[steam_name].finish()
end
