-- Adwisp playback state defaults.
-- Property observation stays in the entry point so lifecycle and cleanup remain explicit.

return {
    visible = false,
    paused = false,
    time_pos = 0,
    duration = 0,
    title = "",
    volume = 100,
    mute = false,
    playlist_pos = -1,
    playlist_count = 0,
}
