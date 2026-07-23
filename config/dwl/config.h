/* Taken from https://github.com/djpohly/dwl/issues/466 */
#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }

static const int sloppyfocus               = 1;
static const int bypass_surface_visibility = 0;
static const unsigned int borderpx         = 1;
static const float rootcolor[]             = COLOR(0x000000ff);
static const float bordercolor[]           = COLOR(0x222222ff);
static const float focuscolor[]            = COLOR(0x222222ff);
static const float urgentcolor[]           = COLOR(0xff0000ff);
static const float fullscreen_bg[]         = {0.0f, 0.0f, 0.0f, 1.0f};

#define TAGCOUNT (10)

static int log_level = WLR_ERROR;

static const Rule rules[] = {
	{ NULL, NULL, 0, 0, -1 },
};

static const Layout layouts[] = {
	{ "[]=", tile },
	{ "><>", NULL },
	{ "[M]", monocle },
};

static const MonitorRule monrules[] = {
	{ "eDP-1",    0.55f, 1, 2, &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL, 0,    0 },
	{ "HDMI-A-2", 0.55f, 1, 1, &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL, 1440, 0 },
	{ NULL,       0.55f, 1, 1, &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL, -1,  -1 },
};

static const struct xkb_rule_names xkb_rules = {
	.layout = "us",
};

static const int repeat_rate = 25;
static const int repeat_delay = 600;

static const int tap_to_click = 1;
static const int tap_and_drag = 1;
static const int drag_lock = 1;
static const int natural_scrolling = 1;
static const int disable_while_typing = 1;
static const int left_handed = 0;
static const int middle_button_emulation = 0;
static const enum libinput_config_scroll_method scroll_method = LIBINPUT_CONFIG_SCROLL_2FG;
static const enum libinput_config_click_method click_method = LIBINPUT_CONFIG_CLICK_METHOD_BUTTON_AREAS;
static const uint32_t send_events_mode = LIBINPUT_CONFIG_SEND_EVENTS_ENABLED;
static const enum libinput_config_accel_profile accel_profile = LIBINPUT_CONFIG_ACCEL_PROFILE_FLAT;
static const double accel_speed = 0.0;
static const enum libinput_config_tap_button_map button_map = LIBINPUT_CONFIG_TAP_MAP_LRM;

#define MODKEY WLR_MODIFIER_LOGO

#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

static const char *termcmd[] = { "foot", NULL };
static const char *launchercmd[] = { "/bin/sh", "-c", "~/.config/rofi/scripts/launcher.sh", NULL };
static const char *emojicmd[] = { "rofi", "-show", "emoji", NULL };
static const char *filescmd[] = { "nautilus", NULL };
static const char *lockcmd[] = { "swaylock", "-f", "-c", "000000", NULL };

#define TAGKEYS(KEY,SKEY,TAG) \
	{ MODKEY,                    KEY,  view, {.ui = 1 << TAG} }, \
	{ MODKEY|WLR_MODIFIER_SHIFT, SKEY, tag,  {.ui = 1 << TAG} }

static const Key keys[] = {
	{ MODKEY, XKB_KEY_o,      spawn, SHCMD("grim -g \"$(slurp)\" ~/me/screenshots/$(date +'%s_scrnsht.png')") },
	{ MODKEY, XKB_KEY_space,  spawn, {.v = launchercmd} },
	{ MODKEY, XKB_KEY_period, spawn, {.v = emojicmd} },
	{ MODKEY, XKB_KEY_t,      spawn, {.v = termcmd} },
	{ MODKEY, XKB_KEY_e,      spawn, {.v = filescmd} },
	{ MODKEY, XKB_KEY_l,      spawn, {.v = lockcmd} },
	{ MODKEY, XKB_KEY_c,      killclient, {0} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_Escape, quit, {0} },

	{ MODKEY, XKB_KEY_f, togglefloating, {0} },
	{ MODKEY, XKB_KEY_u, togglefullscreen, {0} },
	{ MODKEY, XKB_KEY_x, focusstack, {.i = -1} },
	{ MODKEY, XKB_KEY_m, focusstack, {.i = -1} },
	{ MODKEY, XKB_KEY_w, focusstack, {.i = +1} },
	{ MODKEY, XKB_KEY_q, focusstack, {.i = +1} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_x, setmfact, {.f = -0.05f} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_w, setmfact, {.f = +0.05f} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_m, incnmaster, {.i = +1} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_q, incnmaster, {.i = -1} },
	{ MODKEY, XKB_KEY_Return, zoom, {0} },
	{ MODKEY, XKB_KEY_Tab, setlayout, {0} },

	TAGKEYS(XKB_KEY_1, XKB_KEY_exclam, 0),
	TAGKEYS(XKB_KEY_2, XKB_KEY_at, 1),
	TAGKEYS(XKB_KEY_3, XKB_KEY_numbersign, 2),
	TAGKEYS(XKB_KEY_4, XKB_KEY_dollar, 3),
	TAGKEYS(XKB_KEY_5, XKB_KEY_percent, 4),
	TAGKEYS(XKB_KEY_6, XKB_KEY_asciicircum, 5),
	TAGKEYS(XKB_KEY_7, XKB_KEY_ampersand, 6),
	TAGKEYS(XKB_KEY_8, XKB_KEY_asterisk, 7),
	TAGKEYS(XKB_KEY_9, XKB_KEY_parenleft, 8),
	TAGKEYS(XKB_KEY_0, XKB_KEY_parenright, 9),

	{ 0, XKB_KEY_XF86AudioRaiseVolume, spawn, SHCMD("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+") },
	{ 0, XKB_KEY_XF86AudioLowerVolume, spawn, SHCMD("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") },
	{ 0, XKB_KEY_XF86AudioMute, spawn, SHCMD("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") },
	{ 0, XKB_KEY_XF86AudioMicMute, spawn, SHCMD("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle") },
	{ 0, XKB_KEY_XF86MonBrightnessUp, spawn, SHCMD("brightnessctl s 10%+") },
	{ 0, XKB_KEY_XF86MonBrightnessDown, spawn, SHCMD("brightnessctl s 10%-") },
	{ 0, XKB_KEY_XF86AudioNext, spawn, SHCMD("playerctl next") },
	{ 0, XKB_KEY_XF86AudioPause, spawn, SHCMD("playerctl play-pause") },
	{ 0, XKB_KEY_XF86AudioPlay, spawn, SHCMD("playerctl play-pause") },
	{ 0, XKB_KEY_XF86AudioPrev, spawn, SHCMD("playerctl previous") },

	{ WLR_MODIFIER_CTRL|WLR_MODIFIER_ALT, XKB_KEY_Terminate_Server, quit, {0} },
#define CHVT(n) { WLR_MODIFIER_CTRL|WLR_MODIFIER_ALT, XKB_KEY_XF86Switch_VT_##n, chvt, {.ui = (n)} }
	CHVT(1), CHVT(2), CHVT(3), CHVT(4), CHVT(5), CHVT(6),
	CHVT(7), CHVT(8), CHVT(9), CHVT(10), CHVT(11), CHVT(12),
};

static const Button buttons[] = {
	{ MODKEY, BTN_LEFT,  moveresize, {.ui = CurMove} },
	{ MODKEY, BTN_RIGHT, moveresize, {.ui = CurResize} },
};
