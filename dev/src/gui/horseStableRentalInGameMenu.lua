--
--
--

HorseStableRentalInGameMenu = {}

local HorseStableRentalInGameMenu_mt = Class(HorseStableRentalInGameMenu, TabbedMenuFrameElement)

HorseStableRentalInGameMenu.CONTROLS = {
    HORSE_STABLE_RENTAL_PAGE = "horseStableRentalPage"
}

function HorseStableRentalInGameMenu.new(subclass_mt)
	local self = TabbedMenuFrameElement.new(nil, subclass_mt or HorseStableRentalInGameMenu_mt)

	self:registerControls(HorseStableRentalInGameMenu.CONTROLS)

	return self
end