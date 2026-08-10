-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║                       H Y P R L A N D                             ║
-- ║      atengku · RTX 5080 · 3 monitors · Catppuccin Mocha            ║
-- ╚═══════════════════════════════════════════════════════════════════╝
--
-- WHY LUA AND NOT hyprland.conf:
--   Hyprland 0.56 prints on startup:
--     "You are using the .conf config format, support for which will be
--      removed in Hyprland 0.57."
--   That is the NEXT release, so .conf would break on a routine
--   pacman -Syu. This file is the supported format going forward.
--
-- CONSEQUENCE TO REMEMBER:
--   Under the Lua parser `hyprctl keyword ...` does NOT work. It errors
--   with "keyword can't work with non-legacy parsers. Use eval."
--   The equivalent is:
--     hyprctl eval 'hl.config({ general = { gaps_out = 20 } })'
--   Any .conf snippet copied from a forum must be translated first.
--
-- Validate before logging out — this is not optional, a broken config
-- means a black screen and a bounce back to sddm:
--   Hyprland --verify-config
--
-- Previous .conf version kept at ~/.config/hypr/conf.bak/ for reference.

--------------------------------------------------------------------------
-- MONITORS
--------------------------------------------------------------------------
--
-- ⚠ MATCHED BY DESCRIPTION, NEVER BY CONNECTOR NAME (DP-N).
--
-- This box has two GPUs. DRM connector numbering depends on which
-- driver's modules initialise first:
--
--     nvidia late  -> amdgpu takes DP-1..3, nvidia gets DP-4..6
--     nvidia early -> nvidia takes DP-1..3, amdgpu gets DP-4..6
--
-- Putting the nvidia modules in the initramfs flipped exactly that, and
-- every hardcoded `DP-4` silently stopped matching: all three screens
-- dropped to 60Hz in the wrong order, workspaces detached, and waybar
-- showed no bars at all because its outputs no longer existed.
--
-- `desc:` matches the make/model string and does not care about driver
-- load order, kernel version, or plug order.
--   See the strings with:  hyprctl monitors | grep description

local AOC  = "desc:AOC AG273F1G8R3"
local BENQ = "desc:BNQ XL2566X+"
local MSI  = "desc:Microstep MPG321UX OLED"

-- Physical layout, left to right:
--
--   ┌──────────┐┌──────────┐┌────────────────────┐
--   │   AOC    ││   BenQ   ││                    │
--   │  1080p   ││  1080p   ││    MSI 4K OLED     │
--   │  240 Hz  ││  400 Hz  ││   240Hz, scale 1.5 │
--   └──────────┘└──────────┘│                    │
--                 primary   └────────────────────┘
--
-- The 1080p panels are pushed down 180px so all three are vertically
-- CENTRED against the taller 4K — otherwise the pointer snags on the
-- height mismatch when crossing screens.
-- Logical desktop: 6400x1440 (MSI is 3840/1.5 = 2560 wide).

hl.monitor({ output = AOC,  mode = "1920x1080@239.96", position = "0x180",    scale = 1 })
hl.monitor({ output = BENQ, mode = "1920x1080@400.00", position = "1920x180", scale = 1 })
hl.monitor({ output = MSI,  mode = "3840x2160@239.99", position = "3840x0",   scale = 1.5 })

-- Catch-all for anything plugged in later. Keep LAST.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })


--------------------------------------------------------------------------
-- WORKSPACES -> MONITORS
--------------------------------------------------------------------------
--   1 2 3  -> BenQ  (primary, session starts here)
--   4 5 6  -> MSI 4K
--   7 8 9  -> AOC
--     10   -> BenQ  (spare)
--
-- Each monitor owns its workspaces, so SUPER+5 always lands on the 4K
-- and SUPER+8 always on the AOC, wherever focus happens to be.

local WS_MONITOR = {
    [1] = BENQ, [2] = BENQ, [3] = BENQ, [10] = BENQ,
    [4] = MSI,  [5] = MSI,  [6] = MSI,
    [7] = AOC,  [8] = AOC,  [9] = AOC,
}
-- The first workspace on each monitor is that monitor's default.
local WS_DEFAULT = { [1] = true, [4] = true, [7] = true }

for ws, mon in pairs(WS_MONITOR) do
    hl.workspace_rule({
        workspace = tostring(ws),
        monitor   = mon,
        default   = WS_DEFAULT[ws] or nil,
        -- persistent = the workspace always exists, even when empty, so
        -- waybar draws 1 2 3 on the BenQ instead of just the one in use.
        --
        -- Done HERE rather than with waybar's own persistent-workspaces:
        -- that field keys on output NAMES (DP-N), which is exactly the
        -- fragile identifier this whole config avoids. Letting Hyprland
        -- own the workspaces means waybar just reports what exists.
        --
        -- 10 is deliberately excluded — it stays a scratch workspace that
        -- only appears when you actually put something on it.
        persistent = (ws ~= 10) or nil,
    })
end

-- "Smart gaps": a lone tiled window loses gaps, border and rounding so
-- you get every pixel. Very noticeable on the 1080p panels.
--   w[tv1] = workspace with exactly one tiled visible window
--   f[1]   = workspace with one fullscreen window
for _, sel in ipairs({ "w[tv1]", "f[1]" }) do
    hl.workspace_rule({
        workspace   = sel,
        gaps_out    = 0,
        gaps_in     = 0,
        no_border   = true,
        no_rounding = true,
    })
end


--------------------------------------------------------------------------
-- ENVIRONMENT
--------------------------------------------------------------------------
--
-- ⚠ DO NOT set AQ_DRM_DEVICES to a /dev/dri/by-path/... path.
--
-- It is a COLON-separated list, and by-path names embed the PCI address
-- which itself contains colons:
--     /dev/dri/by-path/pci-0000:01:00.0-card
-- aquamarine splits that into "/dev/dri/by-path/pci-0000", "01" and
-- "00.0-card", finds no DRM device, and Hyprland aborts at startup with
--     what():  CBackend::create() failed!
-- i.e. log in -> black screen -> back to sddm. Learned the hard way.
--
-- Left unset: aquamarine enumerates both GPUs and drives the one with
-- monitors attached, which is the NVIDIA card.
--
-- If a reboot ever DOES pick the wrong GPU, use a colon-free symlink:
--   sudo tee /etc/udev/rules.d/99-nvidia-dri.rules <<'EOF'
--   SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:01:00.0", SYMLINK+="dri/nvidia-card"
--   EOF
--   sudo udevadm control --reload && sudo udevadm trigger
-- then: hl.env("AQ_DRM_DEVICES", "/dev/dri/nvidia-card")

-- NVIDIA
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
-- Verified present: /usr/lib/gbm/nvidia-drm_gbm.so
hl.env("GBM_BACKEND", "nvidia-drm")

-- Session identity
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Cursor. Bibata ships XCursor only — no hyprcursor manifest exists for
-- it, so HYPRCURSOR_THEME is deliberately unset (pointing it at a theme
-- with no .hl manifest just warns on every startup).
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Toolkits
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("GDK_BACKEND", "wayland,x11")

-- Apps
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")
hl.env("EDITOR", "nvim")
hl.env("TERMINAL", "ghostty")


--------------------------------------------------------------------------
-- LOOK AND FEEL — Catppuccin Mocha
--------------------------------------------------------------------------

local C = {
    rosewater = "rgb(f5e0dc)", flamingo = "rgb(f2cdcd)", pink   = "rgb(f5c2e7)",
    mauve     = "rgb(cba6f7)", red      = "rgb(f38ba8)", maroon = "rgb(eba0ac)",
    peach     = "rgb(fab387)", yellow   = "rgb(f9e2af)", green  = "rgb(a6e3a1)",
    teal      = "rgb(94e2d5)", sky      = "rgb(89dceb)", blue   = "rgb(89b4fa)",
    sapphire  = "rgb(74c7ec)", lavender = "rgb(b4befe)", text   = "rgb(cdd6f4)",
    surface1  = "rgb(45475a)", base     = "rgb(1e1e2e)", crust  = "rgb(11111b)",
}

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 12,
        border_size = 2,

        col = {
            -- Animated gradient on the focused window
            active_border   = { colors = { "rgba(cba6f7ee)", "rgba(89b4faee)", "rgba(74c7ecee)" }, angle = 45 },
            inactive_border = "rgba(45475aaa)",
        },

        resize_on_border        = true,
        extend_border_grab_area = 12,
        hover_icon_on_border    = true,

        -- You have 240/400Hz panels; tearing buys nothing and interacts
        -- badly with the OLED. Enabled per-window for games instead.
        allow_tearing = false,

        layout = "dwindle",

        snap = { enabled = true, window_gap = 10, monitor_gap = 10 },
    },

    decoration = {
        rounding       = 12,
        rounding_power = 2.2,

        active_opacity     = 1.0,
        inactive_opacity   = 0.96,
        fullscreen_opacity = 1.0,

        dim_inactive = true,
        dim_strength = 0.06,
        dim_special  = 0.3,

        shadow = {
            enabled        = true,
            range          = 24,
            render_power   = 3,
            offset         = "0 4",
            scale          = 0.97,
            color          = "rgba(11111bcc)",
            color_inactive = "rgba(11111b66)",
        },

        blur = {
            enabled = true,
            size    = 6,
            -- 3 passes gives the deep frosted-glass look. Costly on weak
            -- GPUs; the 5080 will not notice. Drop to 2 if the bar ever
            -- stutters.
            passes  = 3,

            noise             = 0.0125,
            contrast          = 1.05,
            brightness        = 0.9,
            vibrancy          = 0.2,
            vibrancy_darkness = 0.15,

            popups             = true,
            popups_ignorealpha = 0.4,
            special            = false,
            new_optimizations  = true,
            xray               = false,
        },
    },

    dwindle = {
        -- NOTE: dwindle.pseudotile was removed in 0.5x; pseudotiling is
        -- now purely a per-window state, toggled with SUPER+P.
        preserve_split  = true,
        smart_split     = false,
        smart_resizing  = true,
        -- Biases splits toward side-by-side on wide areas, which is what
        -- you want on the 4K for code + terminal.
        split_width_multiplier = 1.2,
        force_split            = 2,
    },

    master = {
        new_status     = "master",
        new_on_top     = false,
        mfact          = 0.55,
        orientation    = "left",
        smart_resizing = true,
    },

    misc = {
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,

        -- VRR off. Three mixed panels — and especially an OLED — flicker
        -- visibly on the desktop with adaptive sync. Set 2 for
        -- fullscreen-games-only if you want it.
        vrr = 0,

        background_color = "rgb(11111b)",

        -- INSURANCE: if hyprlock is ever killed while the session is
        -- locked, ext-session-lock keeps the screen locked with no locker
        -- attached ("lockdead"). This lets you just run hyprlock again
        -- instead of being stranded.
        allow_session_lock_restore = true,

        -- A tiled window asking for focus under a fullscreen one exits
        -- fullscreen rather than being hidden behind it.
        on_focus_under_fullscreen = 2,
        -- Cap background window rendering; three screens of windows adds up.
        render_unfocused_fps = 30,

        focus_on_activate            = true,
        animate_manual_resizes       = true,
        animate_mouse_windowdragging = false,
        middle_click_paste           = false,
        enable_swallow               = false,
    },

    cursor = {
        inactive_timeout  = 5,
        hide_on_key_press = false,
        no_warps          = false,
        -- Refocusing a window returns the cursor to where you last left
        -- it inside that window. Saves pointer-hunting across 6400px.
        persistent_warps  = true,
    },

    render = {
        -- Skips compositing for a solitary fullscreen window (lower
        -- latency) but fights always-on blur and can black-flicker on
        -- multi-GPU NVIDIA. Off.
        direct_scanout = false,
    },

    ecosystem = {
        no_update_news  = true,
        no_donation_nag = true,
    },

    xwayland = {
        -- The 4K runs at scale 1.5 while the others are at 1. XWayland
        -- understands only one global scale, so mixed DPI makes legacy X11
        -- apps blurry. This renders them 1:1 (crisp, small on the 4K)
        -- instead of upscaled-and-fuzzy. Nearly everything is Wayland
        -- native anyway thanks to the env vars above.
        force_zero_scaling = true,
    },
})


--------------------------------------------------------------------------
-- ANIMATIONS
--------------------------------------------------------------------------
-- Snappy, not sluggish — tuned to still feel instant at 400Hz.

hl.curve("easeOutQuint",   { type = "bezier", points = { { 0.23, 1 },    { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear",         { type = "bezier", points = { { 0, 0 },       { 1, 1 } } })
hl.curve("almostLinear",   { type = "bezier", points = { { 0.5, 0.5 },   { 0.75, 1 } } })
hl.curve("quick",          { type = "bezier", points = { { 0.15, 0 },    { 0.1, 1 } } })
hl.curve("overshot",       { type = "bezier", points = { { 0.05, 0.9 },  { 0.1, 1.05 } } })
hl.curve("snappy",         { type = "bezier", points = { { 0.3, 1.2 },   { 0.4, 1 } } })

hl.config({ animations = { enabled = true } })

local ANIM = {
    { leaf = "global",           speed = 8,    bezier = "default" },
    { leaf = "border",           speed = 4,    bezier = "easeOutQuint" },
    { leaf = "borderangle",      speed = 60,   bezier = "linear", style = "loop" },
    { leaf = "windows",          speed = 3.5,  bezier = "snappy",       style = "popin 88%" },
    { leaf = "windowsIn",        speed = 3.2,  bezier = "overshot",     style = "popin 90%" },
    { leaf = "windowsOut",       speed = 2.5,  bezier = "easeOutQuint", style = "popin 92%" },
    { leaf = "windowsMove",      speed = 3.5,  bezier = "easeOutQuint" },
    { leaf = "fade",             speed = 2.5,  bezier = "quick" },
    { leaf = "fadeIn",           speed = 2,    bezier = "almostLinear" },
    { leaf = "fadeOut",          speed = 2,    bezier = "almostLinear" },
    { leaf = "fadeSwitch",       speed = 2,    bezier = "almostLinear" },
    { leaf = "fadeShadow",       speed = 2,    bezier = "almostLinear" },
    { leaf = "fadeDim",          speed = 2,    bezier = "almostLinear" },
    { leaf = "layers",           speed = 3,    bezier = "easeOutQuint" },
    { leaf = "layersIn",         speed = 3,    bezier = "overshot",     style = "slide" },
    { leaf = "layersOut",        speed = 2.5,  bezier = "easeOutQuint", style = "slide" },
    { leaf = "fadeLayersIn",     speed = 2,    bezier = "almostLinear" },
    { leaf = "fadeLayersOut",    speed = 2,    bezier = "almostLinear" },
    { leaf = "workspaces",       speed = 2.6,  bezier = "easeOutQuint", style = "slidefade 20%" },
    { leaf = "specialWorkspace", speed = 3,    bezier = "easeOutQuint", style = "slidevert" },
    { leaf = "zoomFactor",       speed = 5,    bezier = "quick" },
}

for _, a in ipairs(ANIM) do
    hl.animation({
        leaf    = a.leaf,
        enabled = true,
        speed   = a.speed,
        bezier  = a.bezier,
        style   = a.style,
    })
end


--------------------------------------------------------------------------
-- INPUT
--------------------------------------------------------------------------

hl.config({
    input = {
        kb_layout          = "us",
        numlock_by_default = true,

        -- Focus follows the mouse: essential with three monitors.
        follow_mouse   = 1,
        mouse_refocus  = true,
        focus_on_close = 1,

        -- RAW MOUSE INPUT. You have a 400Hz Zowie panel and a PRO X 2
        -- DEX, so accel_profile = flat maps the sensor 1:1 — the same
        -- feel as Windows with "Enhance pointer precision" off.
        accel_profile  = "flat",
        sensitivity    = 0,
        force_no_accel = false,

        -- Fast repeat makes hjkl navigation in nvim feel right.
        repeat_rate  = 40,
        repeat_delay = 250,

        touchpad = {
            natural_scroll       = false,
            disable_while_typing = true,
            -- snake_case in Lua; the .conf spelling was tap-to-click
            tap_to_click         = true,
            clickfinger_behavior = true,
            scroll_factor        = 0.6,
        },
    },

    binds = {
        -- Do not wrap from the far-left window to the far-right one; on a
        -- 6400px desktop that is disorienting. Focus stops at the edge.
        movefocus_cycles_fullscreen = false,
        workspace_back_and_forth    = false,
        allow_workspace_cycles      = true,
        focus_preferred_method      = 0,
        scroll_event_delay          = 0,
    },
})

-- Touchpad gesture. 0.5x replaced gestures.workspace_swipe /
-- workspace_swipe_fingers with this declaration; the remaining
-- workspace_swipe_* keys below are still valid tuning knobs.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.config({
    gestures = {
        workspace_swipe_distance       = 300,
        workspace_swipe_cancel_ratio   = 0.4,
        workspace_swipe_create_new     = false,
        workspace_swipe_forever        = true,
        workspace_swipe_direction_lock = true,
    },
})


--------------------------------------------------------------------------
-- KEYBINDS
--------------------------------------------------------------------------
--
--   SUPER + h j k l          move FOCUS between windows
--   SUPER + arrows           MOVE the window
--   SUPER + SHIFT + h j k l  SWAP with neighbour
--   SUPER + SHIFT + arrows   RESIZE (hold to repeat)
--
--   SUPER + CTRL + h/l          focus monitor left/right
--   SUPER + CTRL + SHIFT + h/l  throw WINDOW to that monitor
--   SUPER + ALT + h/l           throw WHOLE WORKSPACE to that monitor
--   SUPER + F1/F2/F3            jump to AOC / BenQ / MSI
--
-- SUPER + / shows a searchable cheatsheet generated from this file.

local MOD = "SUPER"
local TERMINAL = "ghostty"
local BROWSER  = "google-chrome-stable"
local FILES    = "dolphin"
local S        = os.getenv("HOME") .. "/.config/hypr/scripts"

local function sh(cmd) return hl.dsp.exec_cmd(cmd) end

-- Every bind carries a `description`.
--
-- This is not decoration: under the Lua parser `hyprctl binds` reports
-- each bind's dispatcher as "__lua" with an opaque closure index for the
-- arg, so there is NO way to recover what a bind does at runtime. The
-- description field is the only human-readable label available, and the
-- SUPER+/ cheatsheet is built entirely from it.
local function bind(keys, dispatcher, desc, opts)
    opts = opts or {}
    opts.description = desc
    return hl.bind(keys, dispatcher, opts)
end

-- ── Applications ──
bind(MOD .. " + Return",         sh(TERMINAL),                                       "Terminal")
bind(MOD .. " + SHIFT + Return", sh("[float; size 1280 800; center] " .. TERMINAL),  "Terminal (floating)")
bind(MOD .. " + E",              sh(FILES),                                          "File manager")
bind(MOD .. " + B",              sh(BROWSER),                                        "Browser")
bind(MOD .. " + SHIFT + B",      sh(BROWSER .. " --incognito"),                      "Browser (incognito)")

-- ── Launcher / search ──
bind(MOD .. " + SPACE",         sh("pkill rofi || rofi -show drun"), "Launch an app")
bind(MOD .. " + SHIFT + SPACE", sh("pkill rofi || rofi -show run"),  "Run a command")
-- rofi's own window mode is X11-only (needs EWMH), so this asks hyprctl.
bind(MOD .. " + W",             sh("pkill rofi || " .. S .. "/windows.sh"), "Switch window (all 3 monitors)")
bind(MOD .. " + V",             sh(S .. "/clipboard.sh"), "Clipboard history")
bind(MOD .. " + PERIOD",        sh(S .. "/emoji.sh"),     "Emoji picker")
bind(MOD .. " + EQUAL",         sh(S .. "/calc.sh"),      "Calculator")
bind(MOD .. " + SLASH",         sh(S .. "/keybinds.sh"),  "This cheatsheet")

-- ── Window state ──
bind(MOD .. " + Q",         hl.dsp.window.close(), "Close window")
bind(MOD .. " + SHIFT + Q", hl.dsp.window.kill(),  "Force kill window")
bind(MOD .. " + F",         hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), "Fullscreen")
bind(MOD .. " + ALT + F",   hl.dsp.window.fullscreen({ mode = "maximized",  action = "toggle" }), "Maximize")
bind(MOD .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }), "Toggle floating")
bind(MOD .. " + P",         hl.dsp.window.pseudo(),   "Pseudotile")
bind(MOD .. " + T",         hl.dsp.layout("togglesplit"), "Toggle split direction")
bind(MOD .. " + X",         hl.dsp.window.pin(),      "Pin above workspaces")
bind(MOD .. " + Z",         hl.dsp.window.center(),   "Centre floating window")
bind(MOD .. " + G",         hl.dsp.group.toggle(),    "Toggle group (tabbed)")
bind(MOD .. " + ALT + TAB", hl.dsp.group.next(),      "Next window in group")

-- ── Focus / move / swap / resize, driven from one table ──
local DIRS = {
    { key = "h", dir = "left",  dx = -60, dy = 0,   arrow = "left",  word = "left" },
    { key = "j", dir = "down",  dx = 0,   dy = 60,  arrow = "down",  word = "down" },
    { key = "k", dir = "up",    dx = 0,   dy = -60, arrow = "up",    word = "up" },
    { key = "l", dir = "right", dx = 60,  dy = 0,   arrow = "right", word = "right" },
}

for _, d in ipairs(DIRS) do
    bind(MOD .. " + " .. d.key,
        hl.dsp.focus({ direction = d.dir }), "Focus " .. d.word)
    bind(MOD .. " + SHIFT + " .. d.key,
        hl.dsp.window.swap({ direction = d.dir }), "Swap window " .. d.word)
    bind(MOD .. " + " .. d.arrow,
        hl.dsp.window.move({ direction = d.dir }), "Move window " .. d.word)
    bind(MOD .. " + SHIFT + " .. d.arrow,
        hl.dsp.window.resize({ x = d.dx, y = d.dy, relative = true }),
        "Resize window " .. d.word, { repeating = true })
end

bind(MOD .. " + TAB",         hl.dsp.window.cycle_next({ next = true }),  "Cycle windows")
bind(MOD .. " + SHIFT + TAB", hl.dsp.window.cycle_next({ next = false }), "Cycle windows (back)")
bind(MOD .. " + grave",       hl.dsp.focus({ workspace = "previous" }),   "Previous workspace")

-- ── Resize submap: SUPER+R then hjkl freely, Esc/Enter to leave ──
hl.define_submap("resize", function()
    for _, d in ipairs(DIRS) do
        local r = hl.dsp.window.resize({ x = d.dx, y = d.dy, relative = true })
        bind(d.key,   r, "Resize " .. d.word, { repeating = true })
        bind(d.arrow, r, "Resize " .. d.word, { repeating = true })
    end
    bind("escape", hl.dsp.submap("reset"), "Leave resize mode")
    bind("Return", hl.dsp.submap("reset"), "Leave resize mode")
end)
bind(MOD .. " + R", hl.dsp.submap("resize"), "Resize mode (then hjkl, Esc to exit)")

-- ── Monitors ──
-- Modifier depth = distance travelled.
bind(MOD .. " + CTRL + h", hl.dsp.focus({ monitor = "l" }),  "Focus monitor left")
bind(MOD .. " + CTRL + l", hl.dsp.focus({ monitor = "r" }),  "Focus monitor right")
bind(MOD .. " + CTRL + k", hl.dsp.focus({ monitor = "+1" }), "Focus next monitor")
bind(MOD .. " + CTRL + j", hl.dsp.focus({ monitor = "-1" }), "Focus previous monitor")

bind(MOD .. " + CTRL + SHIFT + h", hl.dsp.window.move({ monitor = "l", follow = true }), "Throw window to monitor left")
bind(MOD .. " + CTRL + SHIFT + l", hl.dsp.window.move({ monitor = "r", follow = true }), "Throw window to monitor right")

bind(MOD .. " + ALT + h", hl.dsp.workspace.move({ monitor = "l" }), "Move whole workspace to monitor left")
bind(MOD .. " + ALT + l", hl.dsp.workspace.move({ monitor = "r" }), "Move whole workspace to monitor right")

local FKEYS = { { "F1", AOC, "AOC" }, { "F2", BENQ, "BenQ" }, { "F3", MSI, "MSI 4K" } }
for _, f in ipairs(FKEYS) do
    bind(MOD .. " + " .. f[1],         hl.dsp.focus({ monitor = f[2] }), "Jump to " .. f[3])
    bind(MOD .. " + SHIFT + " .. f[1], hl.dsp.window.move({ monitor = f[2], follow = true }), "Send window to " .. f[3])
end

-- ── Workspaces ──
for i = 1, 10 do
    local key = tostring(i % 10) -- 10 maps to the 0 key
    bind(MOD .. " + " .. key,         hl.dsp.focus({ workspace = i }), "Workspace " .. i)
    bind(MOD .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = true }),  "Send window to workspace " .. i)
    bind(MOD .. " + CTRL + " .. key,  hl.dsp.window.move({ workspace = i, follow = false }), "Send window to workspace " .. i .. " (stay here)")
end

bind(MOD .. " + CTRL + left",  hl.dsp.focus({ workspace = "r-1" }), "Previous workspace on this monitor")
bind(MOD .. " + CTRL + right", hl.dsp.focus({ workspace = "r+1" }), "Next workspace on this monitor")
bind(MOD .. " + mouse_down",   hl.dsp.focus({ workspace = "e+1" }), "Next workspace (scroll)")
bind(MOD .. " + mouse_up",     hl.dsp.focus({ workspace = "e-1" }), "Previous workspace (scroll)")

bind(MOD .. " + S",         hl.dsp.workspace.toggle_special("magic"),        "Scratchpad")
bind(MOD .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), "Send window to scratchpad")

-- ── Screenshots ──
bind("PRINT",           sh(S .. "/screenshot.sh region"),  "Screenshot: drag a region")
bind("SHIFT + PRINT",   sh(S .. "/screenshot.sh window"),  "Screenshot: focused window")
bind("CTRL + PRINT",    sh(S .. "/screenshot.sh monitor"), "Screenshot: whole monitor")
bind(MOD .. " + PRINT", sh(S .. "/screenshot.sh edit"),    "Screenshot: region, then annotate")
bind(MOD .. " + SHIFT + C", sh("hyprpicker -a -n"), "Pick a colour (copies hex)")

-- ── Session ──
-- ESCAPE-based so nothing collides with the hjkl grid above.
bind(MOD .. " + ESCAPE",         sh("loginctl lock-session"),            "Lock screen")
bind(MOD .. " + SHIFT + ESCAPE", sh("pkill wlogout || wlogout -b 5"),    "Power menu")
bind(MOD .. " + SHIFT + R",      sh(S .. "/reload.sh"),                  "Reload Hyprland + waybar + swaync")
bind(MOD .. " + N",              sh("swaync-client -t -sw"),             "Notification centre")
bind(MOD .. " + SHIFT + D",      sh("swaync-client -d -sw"),             "Toggle do-not-disturb")
bind(MOD .. " + SHIFT + W",      sh(S .. "/wallpaper.sh"),               "Change wallpaper")
bind(MOD .. " + A",              sh(S .. "/audio.sh toggle"),            "Toggle audio: headset <-> Elgato XLR")
bind(MOD .. " + SHIFT + A",      sh(S .. "/audio.sh list"),              "List audio devices")
bind(MOD .. " + ALT + G",        sh(S .. "/gamemode.sh"),                "Toggle game mode (effects off)")

-- ── Media & hardware keys ──
-- locked = works on the lockscreen; repeating = repeats while held.
bind("XF86AudioRaiseVolume",  sh("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), "Volume up",   { locked = true, repeating = true })
bind("XF86AudioLowerVolume",  sh("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        "Volume down", { locked = true, repeating = true })
bind("XF86AudioMute",         sh("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),       "Mute",        { locked = true })
bind("XF86AudioMicMute",      sh("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),     "Mute mic",    { locked = true })
bind("XF86MonBrightnessUp",   sh("brightnessctl -e4 -n2 set 5%+"),                    "Brightness up",   { locked = true, repeating = true })
bind("XF86MonBrightnessDown", sh("brightnessctl -e4 -n2 set 5%-"),                    "Brightness down", { locked = true, repeating = true })
bind("XF86AudioNext",         sh("playerctl next"),       "Next track",     { locked = true })
bind("XF86AudioPause",        sh("playerctl play-pause"), "Play / pause",   { locked = true })
bind("XF86AudioPlay",         sh("playerctl play-pause"), "Play / pause",   { locked = true })
bind("XF86AudioPrev",         sh("playerctl previous"),   "Previous track", { locked = true })
bind("XF86AudioStop",         sh("playerctl stop"),       "Stop playback",  { locked = true })

-- ── Mouse ──
bind(MOD .. " + mouse:272",         hl.dsp.window.drag(),   "Drag window",   { mouse = true })
bind(MOD .. " + mouse:273",         hl.dsp.window.resize(), "Resize window", { mouse = true })
bind(MOD .. " + SHIFT + mouse:272", hl.dsp.window.resize(), "Resize window", { mouse = true })


--------------------------------------------------------------------------
-- WINDOW RULES
--------------------------------------------------------------------------
--
-- Field names are snake_case. The ones that do NOT exist (all the old
-- run-together spellings): noblur, noshadow, nodim, norounding,
-- bordersize, suppressevent, idleinhibit, nofocus, keepaspectratio.
-- Real names: no_blur, no_shadow, no_dim, border_size, suppress_event,
-- idle_inhibit, no_focus, keep_aspect_ratio. For square corners use
-- rounding = 0 — there is no no_rounding for windows.
-- Inside match{} it is `float` and `pin`, NOT floating/pinned.

hl.window_rule({
    name = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

hl.window_rule({
    name = "floating-defaults",
    match = { float = true },
    center = true,
    rounding = 12,
})

-- Things that should float, with optional size
local FLOATERS = {
    { name = "file-dialogs",   match = { title = "^(Open File|Open Folder|Save File|Save As|Select a File|Choose Files|Open|Save)(.*)$" } },
    { name = "portals",        match = { class = "^(xdg-desktop-portal-gtk|xdg-desktop-portal-hyprland)$" } },
    { name = "polkit",         match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" } },
    { name = "audio",          match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol)$" }, size = "60% 60%" },
    { name = "network-bt",     match = { class = "^(nm-connection-editor|blueman-manager)$" },   size = "50% 60%" },
    { name = "theme-tools",    match = { class = "^(qt5ct|qt6ct|nwg-look|kvantummanager)$" } },
    { name = "archiver",       match = { class = "^(file-roller|org.gnome.FileRoller)$" } },
    { name = "dolphin-progress", match = { class = "^(org.kde.dolphin)$", title = "^(Copying|Moving|Progress)(.*)$" } },
    { name = "chrome-dialogs", match = { class = "^(google-chrome)$", title = "^(Save file|Print|Open Files)(.*)$" } },
}

for _, f in ipairs(FLOATERS) do
    hl.window_rule({ name = "float-" .. f.name, match = f.match, float = true, size = f.size })
end

-- Picture-in-picture: pinned so it survives workspace switches, parked
-- bottom-right and out of the way.
hl.window_rule({
    name  = "pip",
    match = { title = "^(Picture-in-Picture|Picture in picture)$" },
    float = true,
    pin   = true,
    size  = "30% 30%",
    move  = "68% 66%",
    keep_aspect_ratio = true,
})

-- Ghostty gets NO opacity rule: it sets background-opacity = 0.90
-- itself, which fades only the background and leaves glyphs opaque. A
-- compositor rule dims the text too and stacks with Ghostty's own.
hl.window_rule({ name = "kitty-opacity",  match = { class = "^(kitty)$" }, opacity = "0.94 0.90" })
-- Fully opaque browser — transparency behind text you read all day is a tax.
hl.window_rule({ name = "chrome-opaque", match = { class = "^(google-chrome|Google-chrome|chromium)$" }, opacity = "1.0 1.0" })

-- A fullscreen window needs no effects; nothing behind it is visible.
hl.window_rule({
    name = "fullscreen-no-effects",
    match = { fullscreen = true },
    no_blur = true, no_shadow = true, no_dim = true,
})

-- Never lock or blank during fullscreen video / games.
hl.window_rule({ name = "inhibit-idle-fullscreen", match = { class = ".*" }, idle_inhibit = "fullscreen" })

-- Steam sets class steam_app_<id>. Full GPU, zero decoration, and
-- `immediate` allows tearing for the lowest input latency.
hl.window_rule({
    name = "steam-games",
    match = { class = "^(steam_app_\\d+)$" },
    fullscreen = true, no_blur = true, no_shadow = true,
    rounding = 0, border_size = 0, immediate = true,
})

hl.window_rule({
    name = "scratchpad",
    match = { workspace = "special:magic" },
    float = true, size = "70% 70%", center = true,
})


--------------------------------------------------------------------------
-- LAYER RULES
--------------------------------------------------------------------------
-- Field is ignore_alpha (not ignorealpha) and no_anim (not noanim).
--
-- ⚠ waybar names its layer surface after the bar's "name" field, NOT
-- "waybar". config.jsonc defines waybar-primary / waybar-secondary, so
-- matching ^(waybar)$ would silently blur nothing.
--   Verify with: hyprctl layers

local LAYERS = {
    { name = "waybar",         ns = "^(waybar-primary|waybar-secondary)$", blur = true, ignore_alpha = 0.3, xray = false },
    { name = "rofi",           ns = "^(rofi)$",                      blur = true, ignore_alpha = 0.4, animation = "popin 92%" },
    { name = "swaync-center",  ns = "^(swaync-control-center)$",      blur = true, ignore_alpha = 0.4, animation = "slide right" },
    { name = "swaync-popups",  ns = "^(swaync-notification-window)$", blur = true, ignore_alpha = 0.4 },
    { name = "wlogout",        ns = "^(wlogout)$",                   blur = true, ignore_alpha = 0.4, animation = "fade" },
    { name = "no-anim-select", ns = "^(selection)$",                 no_anim = true },
    { name = "no-anim-picker", ns = "^(hyprpicker)$",                no_anim = true },
}

for _, l in ipairs(LAYERS) do
    hl.layer_rule({
        name         = l.name,
        match        = { namespace = l.ns },
        blur         = l.blur,
        ignore_alpha = l.ignore_alpha,
        animation    = l.animation,
        no_anim      = l.no_anim,
        xray         = l.xray,
    })
end


--------------------------------------------------------------------------
-- AUTOSTART
--------------------------------------------------------------------------

hl.on("hyprland.start", function()
    -- Hand the session environment to systemd and D-Bus FIRST, or screen
    -- sharing, file pickers and polkit prompts silently break.
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")

    -- Authentication prompts (Qt, to match dolphin)
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")

    -- Wallpaper daemon, then restore the wallpaper.
    -- swww was renamed to awww upstream; the binary is awww-daemon, and
    -- --format only accepts argb|abgr|rgb|bgr (NOT xrgb).
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("sh -c 'sleep 1 && " .. S .. "/wallpaper.sh init'")

    -- Shell
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")
    hl.exec_cmd("hypridle")

    -- Clipboard history (text + images)
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Cursor theme for XWayland clients
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")

    -- Re-assert the monitor layout a moment after login. DisplayPort link
    -- training on very high refresh panels occasionally settles at 60Hz
    -- on a cold boot.
    hl.exec_cmd("sh -c 'sleep 2 && " .. S .. "/monitors.sh'")
end)
