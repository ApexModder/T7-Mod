#ifdef HUD_DEBUG
	// Setup custom vars for debug rendering
	#undef DT_TEXTSCALE
	#undef DT_TEXTFONT

	#define DT_TEXTSCALE TEXTSIZE_DEFAULT
	#define DT_TEXTFONT UI_FONT_BOLD

	// Defing some debug vars
	#define DBG_X DvarFloat("ui_dbg_x")
	#define DBG_Y (50 + DvarFloat("ui_dbg_y"))
	#define DBG_SPACING_Y (DT_HEIGHT + 2)

	// Have to use multiple DrawText() calls
	// As trying to combine the text and vectors dont render when using LocString()
	// Player Origin
	DRAW_TEXT(
		DBG_X,
		DBG_Y,
		"@MOD_DBG_ORIGIN"
	)

	// Player Angles
	DRAW_TEXT(
		DBG_X,
		DBG_Y + DBG_SPACING_Y,
		"@MOD_DBG_ANGLES"
	)

	// Fullscreen
	DRAW_TEXT(
		DBG_X,
		DBG_Y + DBG_SPACING_Y + DBG_SPACING_Y,
		"@MENU_FULLSCREEN_CAPS"
	)

	// Below here renders unlocalized text
	#undef DT_GET_TEXTWIDTH
	#undef DT_TEXT

	// Updated to not use DT_TEXT()
	#define DT_GET_TEXTWIDTH(textArg) (GetTextWidth(LocString(textArg), DT_TEXTFONT, DT_TEXTSCALE))
	#define DT_TEXT(textArg) textArg

	// Player Origin - Vector
	DRAW_TEXT(
		DBG_X + DT_GET_TEXTWIDTH("@MOD_DBG_ORIGIN") + 2,
		DBG_Y,
		DvarString("ui_dbg_player_origin")
	)

	// Player Angles - Vector
	DRAW_TEXT(
		DBG_X + DT_GET_TEXTWIDTH("@MOD_DBG_ANGLES") + 2,
		DBG_Y + DBG_SPACING_Y,
		DvarString("ui_dbg_player_angles")
	)

	// Fullscreen - Boolean
	DRAW_TEXT_VIS(
		DBG_X + DT_GET_TEXTWIDTH("@MENU_FULLSCREEN_CAPS") + 2,
		DBG_Y + DBG_SPACING_Y + DBG_SPACING_Y,
		"TRUE",
		IS_FULLSCREEN
	)

	DRAW_TEXT_VIS(
		DBG_X + DT_GET_TEXTWIDTH("@MENU_FULLSCREEN_CAPS") + 2,
		DBG_Y + DBG_SPACING_Y + DBG_SPACING_Y,
		"FALSE",
		!IS_FULLSCREEN
	)

	// Below here renders localized text again
	#undef DT_GET_TEXTWIDTH
	#undef DT_TEXT

	#define DT_GET_TEXTWIDTH(textArg) (GetTextWidth(DT_TEXT(textArg), DT_TEXTFONT, DT_TEXTSCALE))
	#define DT_TEXT(textArg) LocString(textArg)

	// Reset back to defauls
	#undef DT_TEXTSCALE
	#undef DT_TEXTFONT

	#define DT_TEXTSCALE TEXTSIZE_LARGE
	#define DT_TEXTFONT UI_FONT_EXTRABIG
#endif