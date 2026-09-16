// Reemplaza los siguientes placeholders en tiempo de ejecución (rmpc-setup):
//   {{MPD_FIFO}}   → /run/user/<UID>/mpd.fifo
//   {{MUSIC_DIR}}  → $HOME/Music
//   {{HOME}}       → $HOME

#![enable(implicit_some)]
#![enable(unwrap_newtypes)]
#![enable(unwrap_variant_newtypes)]
(
    // Conection to MPD using a FIFO socket
    mpd: (
        method: "fifo",
        path: "{{MPD_FIFO}}",
    ),

    // Interfdace options
    show_album_art: true,
    enable_cava: true,
    status_update_interval_ms: 1000,
    volume_step: 5,
    max_fps: 30,
    scrolloff: 0,
    wrap_navigation: false,
    enable_mouse: true,
    select_current_song_on_change: false,
    browser_column_widths: [20, 38, 42],
    auto_refresh: true,
    update_interval: 5,

    cache_dir: Some("/tmp/rmpc/cache"),
    lyrics_dir: Some("{{MUSIC_DIR}}"),
    password: None,
    theme: "catppuccin_mocha",

    on_song_change: ["{{HOME}}/.config/rmpc/notify"],

    // Album art options
    album_art: (
        method: Auto,
        max_size_px: (width: 900, height: 900),
        disabled_protocols: ["http://", "https://"],
        vertical_align: Top,
        horizontal_align: Center,
    ),

    cava: (
        framerate: 60, // default 60
        autosens: true, // default true
        sensitivity: 100, // default 100
        lower_cutoff_freq: 50, // not passed to cava if not provided
        higher_cutoff_freq: 10000, // not passed to cava if not provided
        input: (
            method: Fifo,
            source: "{{MPD_FIFO}}",
            sample_rate: 44100,
            channels: 2,
            sample_bits: 16,
        ),
        smoothing: (
            noise_reduction: 77, // default 77
            monstercat: false, // default false
            waves: false, // default false
        ),
        // this is a list of floating point numbers thats directly passed to cava
        // they are passed in order that they are defined
        eq: [],// ecualizador, empty if not used
    ),
    keybinds: (
        global: {
            ":":       CommandMode,
            ",":       VolumeDown,
            "s":       Stop,
            ".":       VolumeUp,
            "<Tab>":   NextTab,
            "<S-Tab>": PreviousTab,
            "1":       SwitchToTab("Lyrics"),
            "2":       SwitchToTab("Queue"),
            "3":       SwitchToTab("Directories"),
            "4":       SwitchToTab("Artists"),
            "5":       SwitchToTab("Albums"),
            "6":       SwitchToTab("Search"),
            "q":       Quit,
            ">":       NextTrack,
            "p":       TogglePause,
            "<":       PreviousTrack,
            "f":       SeekForward,
            "z":       ToggleRepeat,
            "x":       ToggleRandom,
            "c":       ToggleConsume,
            "v":       ToggleSingle,
            "b":       SeekBack,
            "|":       ShowHelp,
            "I":       ShowCurrentSongInfo,
            "O":       ShowOutputs,
            "P":       ShowDecoders,
        },
        navigation: {
            "k":         Up,
            "j":         Down,
            "h":         Left,
            "l":         Right,
            "<Up>":      Up,
            "<Down>":    Down,
            "<Left>":    Left,
            "<Right>":   Right,
            "<C-k>":     PaneUp,
            "<C-j>":     PaneDown,
            "<C-h>":     PaneLeft,
            "<C-l>":     PaneRight,
            "<C-u>":     UpHalf,
            "N":         PreviousResult,
            "a":         Add,
            "A":         AddAll,
            "r":         Rename,
            "n":         NextResult,
            "g":         Top,
            "<Space>":   Select,
            "<C-Space>": InvertSelection,
            "G":         Bottom,
            "<CR>":      Confirm,
            "i":         FocusInput,
            "J":         MoveDown,
            "<C-d>":     DownHalf,
            "/":         EnterSearch,
            "<C-c>":     Close,
            "<Esc>":     Close,
            "K":         MoveUp,
            "D":         Delete,
        },
        queue: {
            "D":       DeleteAll,
            "<CR>":    Play,
            "<C-s>":   Save,
            "a":       AddToPlaylist,
            "d":       Delete,
            "i":       ShowInfo,
            "C":       JumpToCurrent,
        },
    ),

    search: (
        case_sensitive: false,
        mode: Contains,
        tags: [
            (value: "any",         label: "Any Tag"),
            (value: "artist",      label: "Artist"),
            (value: "album",       label: "Album"),
            (value: "title",       label: "Title"),
            (value: "filename",    label: "Filename"),
            (value: "genre",       label: "Genre"),
            (value: "albumartist", label: "Featured"),
        ],
    ),

    artists: (
        album_display_mode: SplitByDate, // How to group albums in the artists tab. Options: None, SplitByYear, SplitByDecade, SplitByDate
        album_sort_by: Date,             // How to sort albums in the artists tab. Options: Date, Name, OriginalOrder
    ),

    tabs: [
        (
            name: "Lyrics",
            pane: Split(
                direction: Vertical,
                panes: [
                    (size: "25%", pane: Pane(AlbumArt)),
                    (size: "75%", pane: Pane(Lyrics), vertical_align: Bottom),
                ],
            ),
        ),
        (
            name: "Queue",
            pane: Split(
                direction: Horizontal,
                panes: [
                    (size: "40%", pane: Split(
                        direction: Vertical,
                        panes: [
                            (size: "60%", pane: Pane(AlbumArt)), // Album art takes % of the left side
                            (size: "40%", pane: Pane(Lyrics)),   // Lyrics takes % of the left side
                        ],
                    )),
                    (size: "60%", pane: Split(
                        direction: Vertical,
                        panes: [
                            (size: "30%", pane: Pane(Queue)), // Queue takes % of the right side
                            (size: "70%", pane: Pane(Cava)),  // Cava takes % of the right side
                        ],
                    )),
                ],
            ),
        ),
        (name: "Directories", pane: Pane(Directories)),
        (name: "Artists",     pane: Pane(Artists)),
        (name: "Albums",      pane: Pane(Albums)),
        (name: "Search",      pane: Pane(Search)),
    ],
)
