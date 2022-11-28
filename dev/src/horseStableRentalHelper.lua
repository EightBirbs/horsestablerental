--
-- Contains common helper methods
--
HorseStableRentalHelper = {}

function HorseStableRentalHelper:containsHorseHusbandryWithId(husbandries, id)
    for _, husbandry in pairs(husbandries) do
       if husbandry.id == id then
            return true
       end
    end

    return false
end

function HorseStableRentalHelper:getHorseHusbandryWithId(husbandries, id)
    for _, husbandry in pairs(husbandries) do
       if husbandry.id == id then
            return husbandry
       end
    end

    return nil
end

function HorseStableRentalHelper:getRandomHorseSubType()
    local horseSubTypes = g_currentMission.animalSystem.nameToType["HORSE"].subTypes
    local randomValue = math.random(1, 8)

    return horseSubTypes[randomValue]
end

-- Test Utils
function HorseStableRentalHelper:addFoodToHusbandry(placeable, amount)
    if placeable["spec_husbandryFood"] ~= nil then
        local husbandryFood = placeable.spec_husbandryFood

        for fillType, fillLevel in pairs(husbandryFood.fillLevels) do
            husbandryFood.fillLevels[fillType] = amount
        end
    end
end

function HorseStableRentalHelper:addWaterToHusbandry(placeable, amount)
    if placeable["spec_husbandry"] ~= nil then
        local husbandryStorage = placeable.spec_husbandry.storage

        for fillType, fillLevel in pairs(husbandryStorage.fillLevels) do
            if fillType == FillType.WATER then
                husbandryStorage.fillLevels[fillType] = amount
            end
        end
    end
end