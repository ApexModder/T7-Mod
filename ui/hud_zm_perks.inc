#define PERK_ICON_X(perk) (DvarFloat("ui_zm_perk_" + perk + "_x"))
#define PERK_ICON_IMAGE(perk) (DvarString("ui_zm_perk_" + perk + "_image"))
#define PERK_ICON_ALPHA(perk) (DvarFloat("ui_zm_perk_" + perk + "_alpha"))

#define PERK_X_START 0
#define PERK_Y 386
#define PERK_IMAGE_SIZE 24

#define PERK_X(perk) (PERK_X_START + PERK_ICON_X(perk))

#define DRAW_PERK_SLOT(perk) \
	itemDef \
	{ \
		type		ITEM_TYPE_IMAGE \
		style		WINDOW_STYLE_SHADER \
		rect		0 PERK_Y PERK_IMAGE_SIZE PERK_IMAGE_SIZE \
		exp			rect X(PERK_X(perk)) \
		exp			material(PERK_ICON_IMAGE(perk)) \
		foreColor	1 1 1 1 \
		exp			foreColor A(PERK_ICON_ALPHA(perk)) \
		visible		when(PERK_ICON_IMAGE(perk) != "" && PERK_ICON_ALPHA(perk) > 0) \
		decoration \
	}

// World at War
DRAW_PERK_SLOT("jugg")
DRAW_PERK_SLOT("doubletap")
DRAW_PERK_SLOT("revive")
DRAW_PERK_SLOT("speed_cola")

// Black Ops 1
DRAW_PERK_SLOT("divetonuke")
DRAW_PERK_SLOT("marathon")
DRAW_PERK_SLOT("deadshot")
DRAW_PERK_SLOT("mule_kick")

// Black Ops 2
DRAW_PERK_SLOT("tombstone")
DRAW_PERK_SLOT("chugabud")
DRAW_PERK_SLOT("cherry")
DRAW_PERK_SLOT("vulture")

// Black Ops 3
DRAW_PERK_SLOT("widows")