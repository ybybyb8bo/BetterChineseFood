-- Ensure the Recipe and Recipe.OnCanPerform tables exist
Recipe = Recipe or {}
Recipe.OnCanPerform = Recipe.OnCanPerform or {}

-- Initialize cache tables
local playerTickCache = {}   -- Stores tick counters for each player
local playerResultCache = {} -- Stores last results for each player

-- Function to check if the player is close to a valid cooking utility
local function isCloseToCookingUtil(maxDistance)
    local playerObj = getPlayer()
    if not playerObj then
        print("Error: playerObj is nil")
        return false
    end

    -- Check if getUsername method exists
    if not playerObj.getUsername then
        print("Error: playerObj.getUsername is not available")
        return false
    end

    -- Get the player's username
    local playerID = playerObj:getUsername()
    if not playerID or playerID == "" then
        print("Warning: getUsername() returned nil or empty string")
        playerID = "singleplayer"
    end

    -- Initialize tick counter for the player if not already set
    if not playerTickCache[playerID] then
        playerTickCache[playerID] = 0
        playerResultCache[playerID] = false -- Default to false
    end

    -- Increment the tick counter
    playerTickCache[playerID] = playerTickCache[playerID] + 1

    -- Check if it's time to perform the computation
    if playerTickCache[playerID] >= 30 then
        -- Reset the tick counter
        playerTickCache[playerID] = 0

        -- Perform the heavy computation
        local pX, pY, pZ = playerObj:getX(), playerObj:getY(), playerObj:getZ()
        local maxDistanceSquared = maxDistance * maxDistance

        local cookingUtils = {
            Stove = true,
            Barbecue = true,
            Fireplace = true,
            StoneFurnace = true,
            Fire = true,
        }

        local radius = 5
        local result = false

        -- Iterate over the nearby grid squares
        for dx = -radius, radius do
            for dy = -radius, radius do
                local x = math.floor(pX) + dx
                local y = math.floor(pY) + dy
                local square = getCell():getGridSquare(x, y, pZ)
                if square then
                    -- Check each object in the square
                    for i = 0, square:getObjects():size() - 1 do
                        local obj = square:getObjects():get(i)
                        local objName = obj:getObjectName()
                        if cookingUtils[objName] then
                            -- Get object's position
                            local objX = obj:getX() + 0.5
                            local objY = obj:getY() + 0.5
                            local objZ = obj:getZ()

                            -- Calculate squared distance
                            local dx = objX - pX
                            local dy = objY - pY
                            local distanceSquared = dx * dx + dy * dy

                            if distanceSquared <= maxDistanceSquared then
                                -- Line of sight check
                                local losResult = LosUtil.lineClear(playerObj:getCell(), pX, pY, pZ, objX, objY, objZ, false)
                                if tostring(losResult) ~= "Blocked" then
                                    -- Check if the cooking utility is active
                                    if (obj.getLife and obj:getLife() > 0) or
                                       (obj.getLightRadius and obj:getLightRadius() > 1) or
                                       (obj.isLit and obj:isLit()) or
                                       (obj.isFireStarted and obj:isFireStarted()) or
                                       (obj.Activated and obj:Activated()) then
                                        result = true
                                        break
                                    end
                                end
                            end
                        end
                    end
                    if result then break end
                end
            end
            if result then break end
        end

        -- Cache the result for this player
        playerResultCache[playerID] = result
    end

    -- Return the cached result
    return playerResultCache[playerID]
end

-- Define the OnCanPerform function for your recipe
function Recipe.OnCanPerform.IsNearValidCookingUtility(recipe, playerObj)
    return isCloseToCookingUtil(1.2)
end