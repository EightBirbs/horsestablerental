--
-- Handles all functionalities that are related to the config file
--

HorseStableRentalConfig = {}
HorseStableRentalConfig.xmlFile = {}
HorseStableRentalConfig.horseHusbandries = {}

function HorseStableRentalConfig:getSavegameFolderPath()
    local savegameFolderPath = g_currentMission.missionInfo.savegameDirectory .. "/"

    if savegameFolderPath == nil then
		savegameFolderPath = ('%ssavegame%d'):format(getUserProfileAppPath(), g_currentMission.missionInfo.savegameIndex.."/")
	end

    return savegameFolderPath
end

function HorseStableRentalConfig:getHusbandriesByOwnerFarmId(ownerFarmId)
    local husbandriesOwnedByFarm = {}

    for _, husbandry in pairs(self.horseHusbandries) do
        if husbandry.ownerFarmId == ownerFarmId then
            table.insert(husbandriesOwnedByFarm, husbandry)
        end
    end

    return husbandriesOwnedByFarm
end

function HorseStableRentalConfig:getRentableHusbandries()
    local rentableHusbandries = {}

    for _, husbandry in pairs(self.horseHusbandries) do
        if husbandry.canBeRented then
            table.insert(rentableHusbandries, husbandry)
        end
    end

    return rentableHusbandries
end

function HorseStableRentalConfig:readOrWriteInitially()
    local savegameFolderPath = self:getSavegameFolderPath()

    local rootKey = "horseStableRentalConfig"
    local xmlFile = XMLFile.loadIfExists(rootKey, savegameFolderPath .. rootKey .. ".xml")

    if xmlFile == nil then
        local filePath = savegameFolderPath .. rootKey .. ".xml"
        xmlFile = XMLFile.create(rootKey, filePath, rootKey)
        xmlFile:save()
    end

    self.xmlFile = xmlFile
end

function HorseStableRentalConfig:writeXml()
    local rootKey = "horseStableRentalConfig"

    -- clear before writing actual values
    if self.xmlFile:hasProperty("horseStableRentalConfig.horseHusbandries") then
        self.xmlFile:removeProperty("horseStableRentalConfig.horseHusbandries")
        self.xmlFile:save()
    end

    local index = 0
    for _, husbandry in pairs(self.horseHusbandries) do
        local horseHusbandriesKey = rootKey .. ".horseHusbandries"
        husbandry:toXml(self.xmlFile, horseHusbandriesKey, index)
        index = index + 1
    end

    self.xmlFile:save()
end

function HorseStableRentalConfig:readXml()
    self:readOrWriteInitially()

    self.xmlFile:iterate("horseStableRentalConfig.horseHusbandries.horseHusbandry", function (i, key)
        local horseHusbandry = HorseHusbandry:newDefault()
        horseHusbandry:fromXml(self.xmlFile, key)

        if self:isPlaceableWithIdExisting(horseHusbandry.id) then
            table.insert(self.horseHusbandries, horseHusbandry)
        end
    end)
end

function HorseStableRentalConfig:isPlaceableWithIdExisting(id)
    local placeables = g_currentMission.placeableSystem.placeables

    for _, placeable in pairs(placeables) do
        if placeable.id == id then
            return true
        end
    end

    return false
end