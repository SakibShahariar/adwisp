-- Adwisp playback state defaults.
-- Property observation stays in the entry point so lifecycle and cleanup remain explicit.

return {
    visible = false,
    focus_target = nil,
    paused = false,
    time_pos = 0,
    duration = 0,
    title = "",
    volume = 100,
    speed = 1,
    loop_file = "no",
    ab_loop_a = -1,
    ab_loop_b = -1,
    mute = false,
    buffering = false,
    buffering_progress = 0,
    preview_visible = false,
    preview_time = 0,
    preview_x = 0,
    preview_y = 0,
    preview_width = 0,
    preview_height = 0,
    playlist_pos = -1,
    playlist_count = 0,
}
