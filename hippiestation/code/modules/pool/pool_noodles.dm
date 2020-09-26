//Pool noodles

/obj/item/toy/poolnoodle
	icon = 'hippiestation/icons/obj/toy.dmi'
	icon_state = "noodle"
	name = "pool noodle"
	desc = "A strange, bulky, bendable toy that can annoy people."
	force = 0
	color = "#000000"
	w_class = WEIGHT_CLASS_SMALL
	throwforce = 1
	throw_speed = 10 //weeee
	hitsound = 'sound/weapons/tap.ogg'
	attack_verb_simple = list("flogged", "poked", "jabbed", "slapped", "annoyed")
	lefthand_file = 'hippiestation/icons/mob/inhands/lefthand.dmi'
	righthand_file = 'hippiestation/icons/mob/inhands/righthand.dmi'

/obj/item/toy/poolnoodle/attack(target as mob, mob/living/user as mob)
	..()
	if(prob(80))
		user.emote("spin")
	if(prob(5))
		user.emote("spin")

/obj/item/toy/poolnoodle/red
	inhand_icon_state = "noodlered"

/obj/item/toy/poolnoodle/blue
	inhand_icon_state = "noodleblue"

/obj/item/toy/poolnoodle/yellow
	inhand_icon_state = "noodleyellow"

/obj/item/toy/poolnoodle/red/Initialize()
	. = ..()
	color = "#ff4c4c"

/obj/item/toy/poolnoodle/blue/Initialize()
	. = ..()
	color = "#3232ff"

/obj/item/toy/poolnoodle/yellow/Initialize()
	. = ..()
	color = "#ffff66"
