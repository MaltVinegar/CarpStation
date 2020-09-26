#define IMPORTEDSYNDI "SyndiSnacks"
#define IMPORTEDCOORD(src) "[src ? "([src.x],[src.y],[src.z])" : "nonexistent location"]"
#define IMPORTEDAREACOORD(src) "[src ? "[get_area_name(src, TRUE)] ([src.x], [src.y], [src.z])" : "nonexistent location"]"
#define IMPORTEDONE_ATMOSPHERE			101.325	//! kPa
#define IMPORTEDTCMB					2.7		//! -270.3degC
#define IMPORTEDDIAG_STAT_HUD	"8" //! Silicon/Mech/Circuit Status
#define IMPORTEDDIAG_BATT_HUD	"10"//! Borg/Mech/Circutry power meter
#define IMPORTEDDIAG_CIRCUIT_HUD "13"//! Circuit assembly health bar
#define IMPORTEDDIAG_TRACK_HUD	"14"//! Mech/Silicon tracking beacon, Circutry long range icon
#define IMPORTEDCOLOR_FLOORTILE_GRAY   "#8D8B8B"
#define IMPORTEDENABLE_BITFIELD(variable, flag) (variable |= (flag))
#define IMPORTEDisnum_safe(x) ( isnum((x)) && !isnan((x)) && !isinf((x)) )
#define IMPORTEDINVESTIGATE_CIRCUIT			"circuit"
#define IMPORTEDSIGN(x) ( (x)!=0 ? (x) / abs(x) : 0 )
#define IMPORTEDCLAMP(CLVALUE,CLMIN,CLMAX) clamp(CLVALUE, CLMIN, CLMAX)
#define IMPORTEDTAN(x) tan(x)
#define IMPORTEDCOT(x) (1 / TAN(x))
#define IMPORTEDBE_CLOSE TRUE		//! in the case of a silicon, to select if they need to be next to the atom
#define IMPORTEDFREQ_SYNDICATE 1213  //!  Nuke op comms frequency, dark brown
#define IMPORTEDFREQ_CTF_RED 1215  //!  CTF red team comms frequency, red
#define IMPORTEDFREQ_CTF_BLUE 1217  //!  CTF blue team comms frequency, blue
#define IMPORTEDFREQ_CENTCOM 1337  //!  CentCom comms frequency, gray
#define IMPORTEDFREQ_SIGNALER 1457  //! the default for new signalers
#define IMPORTEDFREQ_COMMON 1459  //! Common comms frequency, dark green
#define IMPORTEDINJECT			5	//! injection
#define IMPORTEDCHAT_FILTER_CHECK(T) (CONFIG_GET(flag/ic_filter_enabled) && config.ic_filter_regex && findtext(T, config.ic_filter_regex))
#define IMPORTEDDEAD		3
#define IMPORTEDINIT_ORDER_CIRCUIT			15
#define IMPORTEDQDEL_LIST(L) if(L) { for(var/I in L) qdel(I); L.Cut(); }
#define IMPORTEDstring2charlist(string) (splittext(string, regex("(.)")) - splittext(string, ""))
#define IMPORTEDREF(thing) (thing && istype(thing, /datum) && (thing:datum_flags & DF_USE_TAG) && thing:tag ? "[thing:tag]" : "\ref[thing]")
