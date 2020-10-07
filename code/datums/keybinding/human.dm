/datum/keybinding/human
	category = CATEGORY_HUMAN
	weight = WEIGHT_MOB

/datum/keybinding/human/can_use(client/user)
	return ishuman(user.mob)

/datum/keybinding/human/quick_equip
	hotkey_keys = list("E")
	name = "quick_equip"
	full_name = "Quick equip"
	description = "Quickly puts an item in the best slot available"
	keybind_signal = COMSIG_KB_HUMAN_QUICKEQUIP_DOWN

/datum/keybinding/human/quick_equip/down(client/user)
	. = ..()
	if(.)
		return
	var/mob/living/carbon/human/H = user.mob
	H.quick_equip()
	return TRUE

/datum/keybinding/human/altquick_equip
	hotkey_keys = list("ShiftE")
	name = "altquick_equip"
	full_name = "Alt Quick equip"
	description = "Quickly puts item in alt hand in the best slot available"
	keybind_signal = COMSIG_KB_HUMAN_ALTQUICKEQUIP_DOWN

/datum/keybinding/human/altquick_equip/down(client/user)
	. = ..()
	if(.)
		return
	var/mob/living/carbon/human/H = user.mob
	H.swap_hand()
	H.quick_equip()
	H.swap_hand()
	return TRUE

/datum/keybinding/human/quick_equip_belt
	hotkey_keys = list("")
	name = "quick_equip_belt"
	full_name = "Quick equip belt"
	description = "Put held thing in belt or take out most recent thing from belt"
	///which slot are we trying to quickdraw from/quicksheathe into?
	var/slot_type = ITEM_SLOT_BELT
	///what we should call slot_type in messages (including failure messages)
	var/slot_item_name = "belt"
	keybind_signal = COMSIG_KB_HUMAN_QUICKEQUIPBELT_DOWN

/datum/keybinding/human/quick_equip_belt/down(client/user)
	. = ..()
	if(.)
		return
	var/mob/living/carbon/human/H = user.mob
	H.smart_equip_targeted(slot_type, slot_item_name)
	return TRUE

/datum/keybinding/human/altquick_equip_belt
	hotkey_keys = list("")
	name = "altquick_equip_belt"
	full_name = "Alt Quick equip belt"
	description = "Put item in other hand in belt or take out most recent thing from belt"
	///which slot are we trying to quickdraw from/quicksheathe into?
	var/slot_type = ITEM_SLOT_BELT
	///what we should call slot_type in messages (including failure messages)
	var/slot_item_name = "belt"
	keybind_signal = COMSIG_KB_HUMAN_ALTQUICKEQUIPBELT_DOWN

/datum/keybinding/human/altquick_equip_belt/down(client/user)
	. = ..()
	if(.)
		return
	var/mob/living/carbon/human/H = user.mob

	H.swap_hand()
	H.smart_equip_targeted(slot_type, slot_item_name)
	H.swap_hand()
	return TRUE



/datum/keybinding/human/quick_equip_belt/quick_equip_bag
	hotkey_keys = list("")
	name = "quick_equip_bag"
	full_name = "Quick equip bag"
	description = "Put held thing in backpack or take out most recent thing from backpack"
	slot_type = ITEM_SLOT_BACK
	slot_item_name = "backpack"
	keybind_signal = COMSIG_KB_HUMAN_BAGEQUIP_DOWN


/datum/keybinding/human/altquick_equip_belt/altquick_equip_bag
	hotkey_keys = list("")
	name = "altquick_equip_bag"
	full_name = "Alt Quick equip bag"
	description = "Put item in otherhand in backpack or take out most recent thing from backpack"
	slot_type = ITEM_SLOT_BACK
	slot_item_name = "backpack"
	keybind_signal = COMSIG_KB_HUMAN_ALTBAGEQUIP_DOWN

/datum/keybinding/human/quick_equip_belt/quick_equip_suit_storage
	hotkey_keys = list("")
	name = "quick_equip_suit_storage"
	full_name = "Quick equip suit storage slot"
	description = "Put held thing in suit storage slot item or take out most recent thing from suit storage slot item"
	slot_type = ITEM_SLOT_SUITSTORE
	slot_item_name = "suit storage slot item"
	keybind_signal = COMSIG_KB_HUMAN_SUITEQUIP_DOWN

/datum/keybinding/human/altquick_equip_belt/altquick_equip_suit_storage
	hotkey_keys = list("")
	name = "altquick_equip_suit_storage"
	full_name = "Quick equip suit storage slot"
	description = "Put item in other hand in suit storage slot item or take out most recent thing from suit storage slot item"
	slot_type = ITEM_SLOT_SUITSTORE
	slot_item_name = "suit storage slot item"
	keybind_signal = COMSIG_KB_HUMAN_ALTSUITEQUIP_DOWN

/datum/keybinding/human/equipment_swap
	hotkey_keys = list("V")
	name = "equipment_swap"
	full_name = "Equipment Swap"
	description = "Equip the currently held item by swapping it out with the already equipped item after a small delay"
	keybind_signal = COMSIG_KB_HUMAN_EQUIPMENTSWAP_DOWN

/datum/keybinding/human/equipment_swap/down(client/user)
	. = ..()
	if(.)
		return
	var/mob/living/carbon/human/H = user.mob
	H.equipment_swap()
	return TRUE

/datum/keybinding/human/altequipment_swap
	hotkey_keys = list("ShiftV")
	name = "altequipment_swap"
	full_name = "Alt Equipment Swap"
	description = "Equip the your inactive hand by swapping it out with the already equipped item after a small delay"
	keybind_signal = COMSIG_KB_HUMAN_ALTEQUIPMENTSWAP_DOWN

/datum/keybinding/human/altequipment_swap/down(client/user)
	. = ..()
	if(.)
		return
	var/mob/living/carbon/human/H = user.mob
	H.swap_hand()
	H.equipment_swap()
	H.swap_hand()
	return TRUE




/datum/keybinding/human/quick_equip_belt/quickleftpocket
	hotkey_keys = list("CtrlQ")
	name = "quickleftpocket"
	full_name = "Quick Left Pocket"
	description = "Switch items in and out of your left pocket"
	slot_type = ITEM_SLOT_LPOCKET
	slot_item_name = "leftpocket"
	keybind_signal = COMSIG_KB_HUMAN_QUICKLEFTPOCKET_DOWN

/datum/keybinding/human/quick_equip_belt/quickrightpocket
	hotkey_keys = list("CtrlE")
	name = "quickrightpocket"
	full_name = "Quick Right Pocket"
	description = "Switch items in and out of your right pocket"
	slot_type = ITEM_SLOT_RPOCKET
	slot_item_name = "rightpocket"
	keybind_signal = COMSIG_KB_HUMAN_QUICKRIGHTPOCKET_DOWN

/datum/keybinding/human/altquick_equip_belt/altquickleftpocket
	hotkey_keys = list("CtrlShiftQ")
	name = "altquickleftpocket"
	full_name = "Alt Quick Left Pocket"
	description = "Switch items in and out of your left pocket"
	slot_type = ITEM_SLOT_LPOCKET
	slot_item_name = "leftpocket"
	keybind_signal = COMSIG_KB_HUMAN_ALTQUICKLEFTPOCKET_DOWN

/datum/keybinding/human/altquick_equip_belt/altquickrightpocket
	hotkey_keys = list("CtrlShiftE")
	name = "altquickrightpocket"
	full_name = "Alt Quick Right Pocket"
	description = "Switch items in and out of your right pocket"
	slot_type = ITEM_SLOT_RPOCKET
	slot_item_name = "rightpocket"
	keybind_signal = COMSIG_KB_HUMAN_ALTQUICKRIGHTPOCKET_DOWN


