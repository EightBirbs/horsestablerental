--
--
--

HorseStableRentalMenu = {
	CONTROLS = {
        HUSBANDRIES_LIST = "husbandriesList",
        HUSBANDRIES_LIST_ITEM = "husbandriesListItem"
	}
}

local HorseStableRentalMenu_mt = Class(HorseStableRentalMenu, TabbedMenuFrameElement)

function HorseStableRentalMenu.new(subclass_mt)
	local self = TabbedMenuFrameElement.new(nil, subclass_mt or HorseStableRentalMenu_mt)

	self:registerControls(HorseStableRentalMenu.CONTROLS)

    self.dataBindings = {}

	return self
end

function HorseStableRentalMenu:onGuiSetupFinished()
    HorseStableRentalMenu:superClass().onGuiSetupFinished(self)
    self.husbandriesList:setDataSource(self)
    self.husbandriesList:setDelegate(self)
end

function HorseStableRentalMenu:getHusbandriesForUser()
    local userId = g_currentMission.playerUserId
    local allFarms = g_farmManager.farms

    for _, farm in pairs(allFarms) do
        for _, player in pairs(farm.players) do
            if player.userId == userId then
                local farmId = farm.farmId
                return FS22_HorseStableRental.HorseStableRental.config:getHusbandriesByOwnerFarmId(farmId)
            end
        end
    end

    return {}
end

function HorseStableRentalMenu:populateCellForItemInSection(list, section, index, cell)
    local automaticString = g_i18n:getText("horseStableRental_automatic")
    local activeString = g_i18n:getText("horseStableRental_renting_active")
    local inactiveString = g_i18n:getText("horseStableRental_renting_inactive")
    local moneyUnitSymbol = self:getMoneyUnitSymbol()

    local horseHusbandry = self:getHusbandriesForUser()[index]
    horseHusbandry:checkForUpdates()

    cell:getAttribute("husbandryName"):setText(horseHusbandry.name)
    cell:getAttribute("foodAmount"):setText(horseHusbandry:getFoodAmountInPercent() .. "%")

    if horseHusbandry.canBeRented then
        cell:getAttribute("income"):setText(tostring(horseHusbandry:calculatePayment()) .. moneyUnitSymbol)
    else
        cell:getAttribute("income"):setText("0" .. moneyUnitSymbol)
    end

    if horseHusbandry:isWaterRequired() then
        cell:getAttribute("waterAmount"):setText(horseHusbandry:getWaterAmountInPercent() .. "%")
    else
        cell:getAttribute("waterAmount"):setText(automaticString)
    end

    if horseHusbandry:isStrawRequired() then
        cell:getAttribute("strawAmount"):setText(horseHusbandry:getStrawAmountInPercentage() .. "%")
    else
        cell:getAttribute("strawAmount"):setText(automaticString)
    end

    local rentalState = horseHusbandry.canBeRented and activeString or inactiveString
    cell:getAttribute("state"):setText(rentalState)
end

function HorseStableRentalMenu:getMoneyUnitSymbol()
    local moneyUnit = g_gameSettings.moneyUnit

    if moneyUnit == GS_MONEY_EURO then
        return g_i18n:getText("unit_euroShort")
    elseif moneyUnit == GS_MONEY_DOLLAR then
        return g_i18n:getText("unit_dollarShort")
    elseif moneyUnit == GS_MONEY_POUND then
        return g_i18n:getText("unit_poundShort")
    end

    return "?"
end

function HorseStableRentalMenu:getNumberOfSections()
	return 1
end

function HorseStableRentalMenu:getNumberOfItemsInSection(list, section)
    return #self:getHusbandriesForUser()
end

function HorseStableRentalMenu:onFrameOpen(element)
	HorseStableRentalMenu:superClass().onFrameOpen(self)
	self.husbandriesList:reloadData()
    FocusManager:setFocus(self.husbandriesList)
end

function HorseStableRentalMenu:onFrameClose()
	HorseStableRentalMenu:superClass().onFrameClose(self)
end

function HorseStableRentalMenu:initialize()
	
end

function HorseStableRentalMenu:onDoubleClick(list, section, index, element)
	local horseHusbandry = FS22_HorseStableRental.HorseStableRental.config.horseHusbandries[index]
    horseHusbandry:changeCanBeRentedState()
    FS22_HorseStableRental.HorseStableRental.config:writeXml()
    self.husbandriesList:reloadData()
end