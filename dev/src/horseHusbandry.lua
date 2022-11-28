--
-- Contains all relevant data and functions that are related to a horse husbandry
--
HorseHusbandry = {
    id = 0,
    ownerFarmId = 0,
    name = "HorseHusbandry",
    isInitialized = false,
    maxNumAnimals = 0,
    canBeRented = true,
    rentableSlots = 0,
    rentPerDay = 150.0,
    placeable = {},
    originalFunctions = {
        supportsRidingFunction = nil,
        canBeSoldFunction = nil,
        animalLoadingTrigger = nil
    }
}

function HorseHusbandry:newDefault()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.isInitialized = false
    o.id = 0
    o.ownerFarmId = 0
    o.name = "HorseHusbandry"
    o.maxNumAnimals = 0
    o.canBeRented = true
    o.rentableSlots = 0
    o.rentPerDay = 150.0
    o.placeable = {}
    o.originalFunctions = {
        supportsRidingFunction = nil,
        canBeSoldFunction = nil,
        animalLoadingTrigger = nil
    }

    return o
end

function HorseHusbandry:new(placeable)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.isInitialized = true
    o.ownerFarmId = placeable.ownerFarmId
    o.id = placeable.id
    o.name = o:getNameOfPlaceable(placeable)
    o.maxNumAnimals = placeable.spec_husbandryAnimals.maxNumAnimals
    o.rentableSlots = o.maxNumAnimals
    o.rentPerDay = 150.0
    o.canBeRented = true
    o.placeable = placeable
    o.originalFunctions = {
        supportsRidingFunction = nil,
        canBeSoldFunction = nil,
        animalLoadingTrigger = nil
    }

    o:storeOriginalFunctionsAndFlagsInPlaceable()
    o:overrideFunctionsAndFlagsInPlaceable()
    o:registerEventListeners()

    return o
end

function HorseHusbandry:initializeAfterLoad(placeable)
    self.placeable = placeable
    self.isInitialized = true
    self:registerEventListeners()

    if self.canBeRented then
        self:storeOriginalFunctionsAndFlagsInPlaceable()
        self:overrideFunctionsAndFlagsInPlaceable()
    end
end

function HorseHusbandry:registerEventListeners()
    -- Horses not yet available, listen to updates
    SpecializationUtil.registerEventListener(self.placeable, "onSell", self)
    SpecializationUtil.registerEventListener(self.placeable, "onOwnerChanged", self)
end

function HorseHusbandry:onSell()
    for index, horseHusbandry in pairs(FS22_HorseStableRental.HorseStableRental.config.horseHusbandries) do
        if horseHusbandry.id == self.id then
            SpecializationUtil.removeEventListener(self, "onSell", horseHusbandry)
            SpecializationUtil.removeEventListener(self, "onOwnerChanged", horseHusbandry)

            table.remove(FS22_HorseStableRental.HorseStableRental.config.horseHusbandries, index)
            FS22_HorseStableRental.HorseStableRental.config:writeXml()
        end
    end
end

function HorseHusbandry:onOwnerChanged()
    for index, horseHusbandry in pairs(FS22_HorseStableRental.HorseStableRental.config.horseHusbandries) do
        if horseHusbandry.id == self.id then
            horseHusbandry.ownerFarmId = horseHusbandry.placeable.ownerFarmId
        end
    end
end

function HorseHusbandry:storeOriginalFunctionsAndFlagsInPlaceable()
    self.originalFunctions.supportsRidingFunction = self.placeable.getAnimalSupportsRiding
    self.originalFunctions.canBeSoldFunction = self.placeable.canBeSold
    self.originalFunctions.animalLoadingTrigger = self.placeable.spec_husbandryAnimals.animalLoadingTrigger.isEnabled
end

function HorseHusbandry:overrideFunctionsAndFlagsInPlaceable()
    -- Disable the possibility to ride horses in the husbandry, as those are not "owned" by you
    self.placeable.getAnimalSupportsRiding = self.getAnimalSupportsRiding
    -- Make sure that the placeable can still be sold, although there are horses on it
    self.placeable.canBeSold = self.canBeSold
    -- Disable the animal loading trigger, so that horses cannot be sold, bought or added
    self.placeable.spec_husbandryAnimals.animalLoadingTrigger.isEnabled = false
end

function HorseHusbandry:resetFunctionsAndFlagsInPlaceable()
    if self.originalFunctions.supportsRidingFunction ~= nil then
        self.placeable.getAnimalSupportsRiding = self.originalFunctions.supportsRidingFunction
    end

    if self.originalFunctions.canBeSoldFunction ~= nil then
        self.placeable.canBeSold = self.originalFunctions.canBeSoldFunction
    end

    if self.originalFunctions.animalLoadingTrigger ~= nil then
        self.placeable.spec_husbandryAnimals.animalLoadingTrigger.isEnabled = self.originalFunctions.animalLoadingTrigger
    end
end

function HorseHusbandry:checkForUpdates()
    if self.placeable ~= nil then
        self:updateName()
    end
end

function HorseHusbandry:updateName()
    local nameOfPlaceable = self:getNameOfPlaceable(self.placeable)
    if nameOfPlaceable ~= self.name then
        self.name = nameOfPlaceable
    end
end

function HorseHusbandry:getNameOfPlaceable(placeable)
    if placeable.name ~= nil then
        return placeable.name
    end

    return placeable.storeItem.name
end

function HorseHusbandry:changeCanBeRentedState()
    local currentRentState = self.canBeRented
    self.canBeRented = not currentRentState

    if self.canBeRented then
        self:overrideFunctionsAndFlagsInPlaceable()
    else
        self:reset()
    end
end

function HorseHusbandry:reset()
    self:resetFunctionsAndFlagsInPlaceable()
    self:removeAllHorses()
end

function HorseHusbandry:getAnimalSupportsRiding(clusterId)
    return false
end

function HorseHusbandry:canBeSold()
    return true
end

function HorseHusbandry:updateHorses(horseCluster)
    self.horses = horseCluster
end

function HorseHusbandry:updateHorseOwnerRelatedValues()
    for _, horse in pairs(self.placeable:getClusters()) do
        horse.fitness = 100
        horse.riding = 100
        horse.dirt = 0
        horse.reproduction = 0
    end
end

function HorseHusbandry:getNumberOfHorses()
    return self.placeable:getNumOfAnimals()
end

function HorseHusbandry:isHusbandryFull()
    local currentSize = self:getNumberOfHorses()

    return currentSize >= self.rentableSlots
end

function HorseHusbandry:createAndAddHorse()
    local randomHorseSubType = HorseStableRentalHelper:getRandomHorseSubType()
    self.placeable:addAnimals(randomHorseSubType, 1, 0)
end

function HorseHusbandry:removeAllHorses()
    local system = self.placeable:getClusterSystem()

    for _, horse in pairs(self.placeable:getClusters()) do
        system:addPendingRemoveCluster(horse)
    end
    self.placeable:raiseActive()
end

function HorseHusbandry:calculatePayment()
    local totalPayment = 0

    for _, horse in pairs(self.placeable:getClusters()) do
        totalPayment = totalPayment + self.rentPerDay
    end

    local paymentReduction = totalPayment / self:calculatePaymentReductionPoints()

    -- Reducing the total amount, if there is no food, water or straw provided
    -- If all required sources are not available, the total payment amount will be zero
    if not self:isFoodAvailable() then
        totalPayment = totalPayment - paymentReduction
    end

    if self:isWaterRequired() and not self:isWaterAvailable() then
        totalPayment = totalPayment - paymentReduction
    end

    if self:isStrawRequired() and not self:isStrawAvailable() then
        totalPayment = totalPayment - paymentReduction
    end

    return totalPayment
end

function HorseHusbandry:calculatePaymentReductionPoints()
    local reductionPoints = 1
    if self:isWaterRequired() then
        reductionPoints = reductionPoints + 1
    end

    if self:isStrawRequired() then
        reductionPoints = reductionPoints + 1
    end

    return reductionPoints
end

function HorseHusbandry:isStrawRequired()
    return self.placeable["spec_husbandry"] ~= nil and self.placeable["spec_husbandryStraw"] ~= nil
end

function HorseHusbandry:isStrawAvailable()
    if self.placeable["spec_husbandry"] ~= nil then
        local husbandryStorage = self.placeable.spec_husbandry.storage

        for fillType, fillLevel in pairs(husbandryStorage.fillLevels) do
            if fillType == FillType.STRAW and fillLevel > 0 then
                return true
            end
        end

        return false
    end

    -- If we do not find a proper food source in the placeable
    -- simply return true
    return true
end

function HorseHusbandry:getStrawAmountInPercentage()
    if self.placeable["spec_husbandry"] ~= nil then
        local husbandryStorage = self.placeable.spec_husbandry.storage

        local totalCapacity = 0
        local fillLevels = 0

        for fillType, capacity in pairs(husbandryStorage.capacities) do
            if fillType == FillType.STRAW then
                totalCapacity = totalCapacity + capacity
            end
        end

        for fillType, fillLevel in pairs(husbandryStorage.fillLevels) do
            if fillType == FillType.STRAW then
                fillLevels = fillLevels + fillLevel
            end
        end

        return tostring(math.floor((fillLevels / totalCapacity) * 100))
    end

    -- If we do not find a proper water source in the placeable
    -- simply return 0
    return "0"
end

function HorseHusbandry:isFoodAvailable()
    if self.placeable["spec_husbandryFood"] ~= nil then
        local husbandryFood = self.placeable.spec_husbandryFood

        for fillType, fillLevel in pairs(husbandryFood.fillLevels) do
            if fillLevel > 0 then
                return true
            end
        end

        return false
    end

    -- If we do not find a proper food source in the placeable
    -- simply return true
    return true
end

function HorseHusbandry:getFoodAmountInPercent()
    if self.placeable["spec_husbandryFood"] ~= nil then
        local husbandryFood = self.placeable.spec_husbandryFood

        local totalCapacity = husbandryFood.capacity
        local fillLevels = 0

        for fillType, fillLevel in pairs(husbandryFood.fillLevels) do
            fillLevels = fillLevels + fillLevel
        end

        return tostring(math.floor((fillLevels / totalCapacity) * 100))
    end

    -- If we do not find a proper food source in the placeable
    -- simply return 0
    return "0"
end

function HorseHusbandry:isWaterRequired()
    if self.placeable["spec_husbandryWater"] ~= nil then
        local husbandryWater = self.placeable.spec_husbandryWater
        return not husbandryWater.automaticWaterSupply
    end

    return false
end

function HorseHusbandry:isWaterAvailable()
    if self.placeable["spec_husbandry"] ~= nil then
        local husbandryStorage = self.placeable.spec_husbandry.storage

        for fillType, fillLevel in pairs(husbandryStorage.fillLevels) do
            if fillType == FillType.WATER and fillLevel > 0 then
                return true
            end
        end

        return false
    end

    -- If we do not find a proper water source in the placeable
    -- simply return true
    return true
end

function HorseHusbandry:getWaterAmountInPercent()
    if self.placeable["spec_husbandry"] ~= nil then
        local husbandryStorage = self.placeable.spec_husbandry.storage

        local totalCapacity = 0
        local fillLevels = 0

        for fillType, capacity in pairs(husbandryStorage.capacities) do
            if fillType == FillType.WATER then
                totalCapacity = totalCapacity + capacity
            end
        end

        for fillType, fillLevel in pairs(husbandryStorage.fillLevels) do
            if fillType == FillType.WATER then
                fillLevels = fillLevels + fillLevel
            end
        end

        return tostring(math.floor((fillLevels / totalCapacity) * 100))
    end

    -- If we do not find a proper water source in the placeable
    -- simply return 0
    return "0"
end

function HorseHusbandry:toXml(xmlFile, xmlKey, index)
    xmlFile:setFloat(xmlKey .. ".horseHusbandry(" .. index .. ")#id", self.id)
    xmlFile:setString(xmlKey .. ".horseHusbandry(" ..index .. ")#name", self.name)
    xmlFile:setFloat(xmlKey .. ".horseHusbandry(" .. index .. ")#ownerFarmId", self.ownerFarmId)
    xmlFile:setInt(xmlKey .. ".horseHusbandry(" .. index .. ")#maxNumAnimals", self.maxNumAnimals)
    xmlFile:setBool(xmlKey .. ".horseHusbandry(" .. index .. ")#canBeRented", self.canBeRented)
    xmlFile:setInt(xmlKey .. ".horseHusbandry(" .. index .. ")#rentableSlots", self.rentableSlots)
    xmlFile:setFloat(xmlKey .. ".horseHusbandry(" .. index .. ")#rentPerDay", self.rentPerDay)
end

function HorseHusbandry:fromXml(xmlFile, key)
    self.id = xmlFile:getFloat(key .. "#id")
    self.name = xmlFile:getString(key .. "#name")
    self.ownerFarmId = xmlFile:getFloat(key .. "#ownerFarmId")
    self.maxNumAnimals = xmlFile:getInt(key .. "#maxNumAnimals")
    self.canBeRented = xmlFile:getBool(key .. "#canBeRented")
    self.rentableSlots = xmlFile:getInt(key .. "#rentableSlots")
    self.rentPerDay = xmlFile:getFloat(key .. "#rentPerDay")
end