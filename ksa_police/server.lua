-- KSA Police v3.0.1: server-owned wanted escalation using the installed Slothbot
-- framework.  No custom client gameplay logic is used.

local CRIME_COOLDOWN, ESCAPE_REDUCTION_DELAY, REPLACEMENT_DELAY = 4000, 75000, 15000
local pursuits, lastCrime, debugPlayers = {}, {}, {}
local dispatchSerial = 0
local policeTeam = getTeamFromName("KSA Police") or createTeam("KSA Police", 40, 110, 255)

local LEVELS = {
    [1] = { units = 3, skins = {280}, weapon = 22, vehicles = {596} },
    [2] = { units = 6, skins = {280}, weapon = 22, vehicles = {596, 596, 523} },
    [3] = { units = 10, skins = {280}, weapon = 25, vehicles = {596, 596, 523, 596, 497} },
    [4] = { units = 14, skins = {285, 280}, weapon = 29, vehicles = {427, 427, 596, 497, 596} },
    [5] = { units = 18, skins = {286, 285, 280}, weapon = 31, vehicles = {490, 490, 427, 596, 497, 523} },
    [6] = { units = 24, skins = {287, 285, 286}, weapon = 31, vehicles = {432, 432, 433, 427, 596, 497, 490} },
}

local function isAdmin(player)
    local account = getPlayerAccount(player)
    return account and not isGuestAccount(account) and isObjectInACLGroup("user." .. getAccountName(account), aclGetGroup("Admin"))
end

local function tell(player, message, r, g, b)
    outputChatBox("[Police] " .. message, player, r or 90, g or 170, b or 255)
end

local function log(player, message)
    if debugPlayers[player] then outputDebugString("ksa_police: " .. getPlayerName(player) .. ": " .. message, 3) end
end

local function eligible(player)
    return isElement(player) and getElementType(player) == "player" and not isPedDead(player)
        and getElementData(player, "loggedin") and getElementInterior(player) == 0 and getElementDimension(player) == 0
end

local function destroyAfterBotTimers(element)
    if isElement(element) then
        setTimer(function(target) if isElement(target) then destroyElement(target) end end, 1300, 1, element)
    end
end

local function clearPursuit(player, immediate)
    local state = pursuits[player]
    if not state then return end
    for _, bot in ipairs(state.bots) do
        if isElement(bot) then
            exports.slothbot:setBotAttackEnabled(bot, false)
            if immediate then destroyElement(bot) else destroyAfterBotTimers(bot) end
        end
    end
    for _, vehicle in ipairs(state.vehicles) do if isElement(vehicle) then destroyElement(vehicle) end end
    pursuits[player] = nil
end

local function setWanted(player, level)
    level = math.max(0, math.min(6, math.floor(tonumber(level) or 0)))
    setPlayerWantedLevel(player, level)
    setElementData(player, "char:wanted", level, false)
    if level == 0 then clearPursuit(player) end
    return level
end

local function spawnPoint(player, index, distance)
    local px, py, pz = getElementPosition(player)
    local angle = math.rad(getPedRotation(player) + 132 + index * 37)
    return px + math.sin(angle) * distance, py + math.cos(angle) * distance, pz + 1.0, math.deg(angle) - 90
end

local function createSceneVehicle(player, state, model, index)
    local x, y, z, rotation = spawnPoint(player, index, 78 + index * 9)
    if model == 497 then z = z + 58 end
    local vehicle = createVehicle(model, x, y, z, 0, 0, rotation)
    if not vehicle then return end
    setElementInterior(vehicle, 0)
    setElementDimension(vehicle, 0)
    setElementFrozen(vehicle, true)
    setVehicleEngineState(vehicle, true)
    if model == 596 or model == 427 or model == 497 then setVehicleSirensOn(vehicle, true) end
    table.insert(state.vehicles, vehicle)
end

local function dispatch(player)
    if not eligible(player) then return end
    local level = getPlayerWantedLevel(player) or 0
    local profile = LEVELS[level]
    if not profile then return clearPursuit(player) end
    clearPursuit(player)
    -- A unique token prevents delayed spawns from an earlier dispatch joining
    -- a replacement pursuit at the same wanted level.
    dispatchSerial = dispatchSerial + 1
    local state = {
        serial = dispatchSerial,
        level = level,
        bots = {}, vehicles = {}, dispatched = getTickCount(), lastSeen = getTickCount(),
    }
    pursuits[player] = state
    for index, model in ipairs(profile.vehicles) do createSceneVehicle(player, state, model, index) end
    for index = 1, profile.units do
        setTimer(function(target, serial, unitIndex)
            local current = pursuits[target]
            if not current or current.serial ~= serial or not eligible(target) or (getPlayerWantedLevel(target) or 0) ~= level then return end
            local x, y, z, rotation = spawnPoint(target, unitIndex, 62 + (unitIndex % 5) * 8)
            local skin = profile.skins[((unitIndex - 1) % #profile.skins) + 1]
            local bot = exports.slothbot:spawnBot(x, y, z, rotation, skin, 0, 0, policeTeam, profile.weapon, "chasing", target)
            if bot and isElement(bot) then
                setElementData(bot, "kp:owner", target, false)
                setElementData(bot, "kp:unit", true, false)
                table.insert(current.bots, bot)
            end
        end, 350 + (index - 1) * 180, 1, player, state.serial, index)
    end
    log(player, "dispatched level " .. level .. ": " .. profile.units .. " officers and " .. #profile.vehicles .. " response vehicles")
end

local function reportCrime(player, severity, reason)
    if not eligible(player) then return end
    local now = getTickCount()
    if now - (lastCrime[player] or 0) < CRIME_COOLDOWN then return end
    lastCrime[player] = now
    local level = setWanted(player, (getPlayerWantedLevel(player) or 0) + severity)
    tell(player, "Wanted level " .. level .. "/6: " .. reason)
    dispatch(player)
end

addEventHandler("onPedDamage", root, function(attacker)
    if not eligible(attacker) then return end
    if getElementData(source, "kp:unit") then return reportCrime(attacker, 2, "assault on police") end
    if not getElementData(source, "isMysteryPed") and not exports.slothbot:isPedBot(source) then reportCrime(attacker, 1, "assault on a civilian") end
end)
addEventHandler("onPedWasted", root, function(_, killer)
    if not eligible(killer) then return end
    if getElementData(source, "kp:unit") then reportCrime(killer, 2, "killing a police officer")
    elseif not getElementData(source, "isMysteryPed") and not exports.slothbot:isPedBot(source) then reportCrime(killer, 1, "killing a civilian") end
end)
addEventHandler("onVehicleStartEnter", root, function(player, seat, jacked)
    if seat == 0 and jacked then reportCrime(player, 1, "carjacking") end
end)
addEventHandler("onPlayerWeaponFire", root, function(weapon)
    if not eligible(source) or (weapon or 0) < 22 then return end
    local px, py, pz = getElementPosition(source)
    for _, ped in ipairs(getElementsByType("ped")) do
        if not getElementData(ped, "kp:unit") and not getElementData(ped, "isMysteryPed") and not exports.slothbot:isPedBot(ped) then
            local x, y, z = getElementPosition(ped)
            if getDistanceBetweenPoints3D(px, py, pz, x, y, z) <= 28 then return reportCrime(source, 1, "firing near civilians") end
        end
    end
end)

setTimer(function()
    local now = getTickCount()
    for player, state in pairs(pursuits) do
        local level = getPlayerWantedLevel(player) or 0
        if not eligible(player) or level == 0 then
            clearPursuit(player)
        else
            local alive, near = 0, false
            local px, py, pz = getElementPosition(player)
            for _, bot in ipairs(state.bots) do
                if isElement(bot) and not isPedDead(bot) then
                    alive = alive + 1
                    local x, y, z = getElementPosition(bot)
                    if getDistanceBetweenPoints3D(px, py, pz, x, y, z) < 360 then near = true end
                end
            end
            if near then state.lastSeen = now end
            if now - state.lastSeen >= ESCAPE_REDUCTION_DELAY then
                local reduced = setWanted(player, level - 1)
                if reduced > 0 then tell(player, "Police lost you. Wanted level reduced to " .. reduced .. "/6.") dispatch(player) end
            elseif alive < math.max(2, math.floor(LEVELS[level].units * 0.55)) and now - state.dispatched >= REPLACEMENT_DELAY then
                dispatch(player)
            end
        end
    end
end, 2500, 0)

local function resetSessionWanted(player)
    if isElement(player) and getElementData(player, "loggedin") then clearPursuit(player); setWanted(player, 0) end
end

addEventHandler("onElementDataChange", root, function(key, _, value)
    if getElementType(source) == "player" and key == "loggedin" and value then setTimer(resetSessionWanted, 900, 1, source) end
end)
addEventHandler("onPlayerWasted", root, function() clearPursuit(source); lastCrime[source] = nil; setWanted(source, 0) end)
addEventHandler("onPlayerQuit", root, function() clearPursuit(source); lastCrime[source] = nil; debugPlayers[source] = nil end)
addEventHandler("onResourceStart", resourceRoot, function()
    for _, player in ipairs(getElementsByType("player")) do setTimer(resetSessionWanted, 900, 1, player) end
end)
addEventHandler("onResourceStop", resourceRoot, function() for player in pairs(pursuits) do clearPursuit(player, true) end end)

addCommandHandler("wanted", function(player, _, level)
    if not isAdmin(player) then return end
    level = tonumber(level)
    if not level or level < 0 or level > 6 then return tell(player, "Usage: /wanted <0-6>", 255, 180, 80) end
    setWanted(player, level)
    if level > 0 then dispatch(player) end
end)
addCommandHandler("policeclear", function(player)
    if not isAdmin(player) then return end
    setWanted(player, 0); tell(player, "Wanted level and police response cleared.")
end)
addCommandHandler("policedebug", function(player, _, mode)
    if not isAdmin(player) then return end
    debugPlayers[player] = mode == "on"; tell(player, "Police debug logging " .. (debugPlayers[player] and "enabled" or "disabled") .. ".")
end)
addCommandHandler("policestatus", function(player)
    if not isAdmin(player) then return end
    local state = pursuits[player]
    tell(player, state and ("Level " .. state.level .. ": " .. #state.bots .. " officers and " .. #state.vehicles .. " response vehicles tracked.") or "No active police response.")
end)
