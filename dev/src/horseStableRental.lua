--
-- Mod entry "class". Contains all functions and subscriptions to mod related services
--
HorseStableRental = {}
HorseStableRental.config = {}

function HorseStableRental:loadMap()
    -- Init math.randomseed with a seed once
    math.randomseed(1337)

    self:mergeModTranslations()

    HorseStableRental.config = HorseStableRentalConfig
    HorseStableRental.config:readXml()
    HorseStableRental.addSettingsPage(g_modsDirectory .. "/FS22_HorseStableRental/")

    g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.hourChanged, self)
    g_messageCenter:subscribe(MessageType.DAY_CHANGED, self.dayChanged, self)
    g_messageCenter:subscribe(MessageType.HUSBANDRY_SYSTEM_ADDED_PLACEABLE, self.husbandryAdded, self)
end

function HorseStableRental:mergeModTranslations()
    -- Taken over from other famous mods (guidanceSteering) as this seems to be necessary to be able to use the tanslations
    local modEnvMeta = getmetatable(_G)
    local env = modEnvMeta.__index
    local modTexts = FS22_HorseStableRental.g_i18n.texts

    local global = env.g_i18n.texts
    for key, text in pairs(modTexts) do
        global[key] = text
    end
end

function HorseStableRental:hourChanged()
    HorseStableRental.config:writeXml()

    for _, horseHusbandry in pairs(HorseStableRental.config:getRentableHusbandries()) do
        if not horseHusbandry:isHusbandryFull() then
            horseHusbandry:createAndAddHorse()
        end

            horseHusbandry:updateHorseOwnerRelatedValues()
    end
end

function HorseStableRental:dayChanged()
    local paymentPerFarm = {}

    for _, horseHusbandry in pairs(HorseStableRental.config:getRentableHusbandries()) do
        local ownerFarmId = horseHusbandry.ownerFarmId
        local paymentForHusbandry = horseHusbandry:calculatePayment()

        if paymentPerFarm[ownerFarmId] == nil then
            paymentPerFarm[ownerFarmId] = paymentForHusbandry
        else
            paymentPerFarm[ownerFarmId] = paymentPerFarm[ownerFarmId] + paymentForHusbandry
        end
    end

    for farmId, payment in pairs(paymentPerFarm) do
        g_currentMission:addMoney(payment, farmId, MoneyType.OTHER, true, true)
    end
end

function HorseStableRental:husbandryAdded()
    local placeables = g_currentMission.placeableSystem.placeables

    for _, placeable in pairs(placeables) do
        if placeable["spec_husbandryAnimals"] ~= nil then
            local animalType = placeable.spec_husbandryAnimals.animalType.name
            local isAlreadyStored = HorseStableRentalHelper:containsHorseHusbandryWithId(HorseStableRental.config.horseHusbandries, placeable.id)

            if animalType == "HORSE" then
                if not isAlreadyStored then
                    local horseHusbandry = HorseHusbandry:new(placeable)
                    table.insert(HorseStableRental.config.horseHusbandries, horseHusbandry)
                    HorseStableRental.config:writeXml()
                else
                    local husbandry = HorseStableRentalHelper:getHorseHusbandryWithId(HorseStableRental.config.horseHusbandries, placeable.id)

                    if not husbandry.isInitialized then
                        husbandry:initializeAfterLoad(placeable)
                    end
                end
            end
        end
    end
end

function HorseStableRental.addSettingsPage(baseDirectory)
	local horseStableRentalMenu = HorseStableRentalMenu.new()
	local horseStableRentalInGameMenu = HorseStableRentalInGameMenu.new()

    g_gui:loadProfiles(Utils.getFilename("xml/gui/guiProfiles.xml", baseDirectory))
	g_gui:loadGui(Utils.getFilename("xml/gui/HorseStableRentalMenu.xml", baseDirectory), "HorseStableRentalMenu", horseStableRentalMenu, true)
	g_gui:loadGui(Utils.getFilename("xml/gui/HorseStableRentalInGameMenu.xml", baseDirectory), "HorseStableRentalInGameMenu", horseStableRentalInGameMenu)

	local inGameMenu = g_currentMission.inGameMenu
	local horseStableRentalPage = horseStableRentalInGameMenu.horseStableRentalPage

	if horseStableRentalPage ~= nil then
		local pagingElement = inGameMenu.pagingElement
		local index = pagingElement:getPageIndexByElement(inGameMenu.pageAnimals) + 1

		PagingElement:superClass().addElement(pagingElement, horseStableRentalPage)
		pagingElement:addPage(string.upper(horseStableRentalPage.name), horseStableRentalPage, "horseStableRental", index)

        local menuIconFileName = Utils.getFilename('resources/menuIcon.dds', baseDirectory)
		inGameMenu:registerPage(horseStableRentalPage, index, HorseStableRental:makeIsHorseStableRentalEnabledPredicate())
		inGameMenu:addPageTab(horseStableRentalPage, menuIconFileName, GuiUtils.getUVs({0,0,1024,1024}))
		inGameMenu.horseStableRentalPage = horseStableRentalPage
	end

    horseStableRentalMenu:initialize()
    horseStableRentalPage:initialize(self)
end

function HorseStableRental:makeIsHorseStableRentalEnabledPredicate()
	return function () return true end
end

addModEventListener(HorseStableRental)