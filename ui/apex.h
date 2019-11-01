// Common
#define SCREEN_WIDTH 640
#define SCREEN_HEIGHT 480

#define ELEM_BASE_ORIGIN 0 0 0 0
#define ELEM_BASE_FORECOLOR 1 1 1 1
#define ELEM_BASE_VISARG 1
#define ELEM_BASE_EXTRAARGS ;

#define IS_FULLSCREEN DvarBool("r_fullscreen")

// Text
#define DT_ITEM_TYPE ITEM_TYPE_TEXT
#define DT_TEXTSCALE TEXTSIZE_LARGE
#define DT_TEXTSTYLE ITEM_TEXTSTYLE_SHADOWED
#define DT_TEXTFONT UI_FONT_EXTRABIG
#define DT_GET_TEXTWIDTH(textArg) (GetTextWidth(DT_TEXT(textArg), DT_TEXTFONT, DT_TEXTSCALE))
#define DT_HEIGHT 20
#define DT_BASE_ORIGIN ELEM_BASE_ORIGIN
#define DT_FORECOLOR ELEM_BASE_FORECOLOR
#define DT_TEXT(textArg) LocString(textArg)

#define DRAW_TEXT(xArg, yArg, textArg) DRAW_TEXT_VIS(xArg, yArg, textArg, ELEM_BASE_VISARG)
#define DRAW_TEXT_VIS(xArg, yArg, textArg, visArg) DRAW_TEXT_EX(xArg, yArg, textArg, visArg, ELEM_BASE_EXTRAARGS)

#define DRAW_TEXT_EX(xArg, yArg, textArg, visArg, extraArgs) \
	itemDef \
	{ \
		type			ITEM_TYPE_TEXT \
		rect			DT_BASE_ORIGIN \
		exp				rect X(xArg) \
		exp				rect Y(yArg) \
		exp				rect W(DT_GET_TEXTWIDTH(textArg)) \
		exp				rect H(DT_HEIGHT) \
		textScale		DT_TEXTSCALE \
		textStyle		DT_TEXTSTYLE \
		textFont		DT_TEXTFONT \
		exp				text(DT_TEXT(textArg)) \
		foreColor		DT_FORECOLOR \
		visible			when(visArg) \
		decoration \
		extraArgs \
	}

// Images
#define DI_ITEM_TYPE ITEM_TYPE_IMAGE
#define DI_ITEM_STYLE WINDOW_STYLE_SHADER
#define DI_BASE_ORIGIN ELEM_BASE_ORIGIN
#define DI_FORECOLOR ELEM_BASE_FORECOLOR

#define DRAW_IMAGE(xArg, yArg, sizeArg, imageArg) DRAW_IMAGE_SIZE(xArg, yArg, sizeArg, sizeArg, imageArg)
#define DRAW_IMAGE_VIS(xArg, yArg, sizeArg, imageArg, visArg) DRAW_IMAGE_SIZE_VIS(xArg, yArg, sizeArg, sizeArg, imageArg, visArg)
#define DRAW_IMAGE_EX(xArg, yArg, sizeArg, imageArg, visArg, extraArgs) DRAW_IMAGE_SIZE_EX(xArg, yArg, sizeArg, sizeArg, imageArg, visArg, extraArgs)
#define DRAW_IMAGE_SIZE(xArg, yArg, wArg, hArg, imageArg) DRAW_IMAGE_SIZE_VIS(xArg, yArg, wArg, hArg, imageArg, ELEM_BASE_VISARG)
#define DRAW_IMAGE_SIZE_VIS(xArg, yArg, wArg, hArg, imageArg, visArg) DRAW_IMAGE_SIZE_EX(xArg, yArg, wArg, hArg, imageArg, visArg, ELEM_BASE_EXTRAARGS)

#define DRAW_IMAGE_SIZE_EX(xArg, yArg, wArg, hArg, imageArg, visArg, extraArgs) \
	itemDef \
	{ \
		type		DI_ITEM_TYPE \
		style		DI_ITEM_STYLE \
		rect		DI_BASE_ORIGIN \
		exp			rect X(xArg) \
		exp			rect Y(yArg) \
		exp			rect W(wArg) \
		exp			rect H(hArg) \
		exp			material(imageArg) \
		foreColor	DI_FORECOLOR \
		visible		when(visArg) \
		decoration \
		extraArgs \
	}