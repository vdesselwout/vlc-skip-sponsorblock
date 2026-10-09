# skip_sponsorblock.lua

A VLC 3.x Lua interface script that automatically skips chapters whose title
starts with `[SponsorBlock]:`, the chapters yt-dlp creates with
`--sponsorblock-mark`.

Each sponsor chapter is skipped **only the first time** it is reached per file.
If you seek back into a skipped chapter, it plays normally and isn't skipped
again. Opening a different file resets this.

Tested on VLC 3.0.24 (Windows). VLC 4 changes the Lua API and is not supported.

## Getting videos with SponsorBlock chapters

```
yt-dlp --sponsorblock-mark all <url>
```

Both `.mp4` and `.mkv` work, since VLC reads the chapter names from either.

## Installation (Windows)

1. Close VLC completely.
2. Copy `skip_sponsorblock.lua` to:
   ```
   %APPDATA%\vlc\lua\intf\skip_sponsorblock.lua
   ```
   Create the `lua\intf` folders if they don't exist. Make sure the file is
   really named `.lua` and not `.lua.txt`. Turn on View → Show → File name
   extensions in Explorer to check.
3. Open `%APPDATA%\vlc\vlcrc` in Notepad (Win+R → `notepad %APPDATA%\vlc\vlcrc`)
   and set these two lines. They already exist, so remove the leading `#` and
   fill in the values:
   ```
   extraintf=luaintf
   lua-intf=skip_sponsorblock
   ```
   If `vlcrc` doesn't exist yet, open VLC, go to Tools → Preferences, click
   Save, close VLC, and try again.
4. Start VLC. No extra console window should appear.

> **Important:** the value must be `luaintf`, not `lua`. Ticking "Lua
> interpreter" in VLC's preferences writes `extraintf=lua`, which starts VLC's
> built-in command-line console instead of this script. If you save
> preferences later, check that this line wasn't changed back.

## Installation (Linux, untested)

Same steps, with these paths:

- Script: `~/.local/share/vlc/lua/intf/skip_sponsorblock.lua`
- Config: `~/.config/vlc/vlcrc`

## Settings

At the top of the script:

| Setting   | Default                 | Meaning                                         |
|-----------|-------------------------|-------------------------------------------------|
| `PATTERN` | `^%[SponsorBlock%]:`    | Lua pattern matched against chapter titles      |
| `POLL_US` | `250000`                | How often to check, in microseconds (4x/second) |
| `DEBUG`   | `true`                  | Log every chapter change and the chapter list   |

Set `DEBUG = false` once everything works. Skips are still logged and shown
on screen.

## Troubleshooting

**A console window opens with "Command Line Interface initialized"**
`vlcrc` has `extraintf=lua`. Change it to `extraintf=luaintf`.

**Nothing is skipped**
The Messages window (Tools → Messages) only shows messages logged after it is
opened, so log to a file instead. In PowerShell:

```powershell
& "C:\Program Files\VideoLAN\VLC\vlc.exe" --file-logging --log-verbose=2 --logfile="$env:TEMP\vlc.log" 'C:\path\to\video.mp4'
```

Use **single quotes** around the video path. In double quotes, PowerShell
treats `$` in filenames as a variable and mangles the path.

After playing past a sponsor chapter, close VLC and run:

```powershell
Select-String -Path "$env:TEMP\vlc.log" -Pattern "lua|sponsorblock|chapter" | Select-Object -First 60 | ForEach-Object { $_.Line }
```

What to look for:

- `Found lua interface script: ...skip_sponsorblock.lua` and
  `[skip_sponsorblock] loaded`: the script loads correctly.
- No such lines: check the file location and the two `vlcrc` lines.
- A `lua error:` line: the script crashed. The message says where.
- Chapters listed as `Chapter 1`, `Chapter 2`, …: VLC isn't reading the real
  chapter names from this file. Remux it to mkv, for example with
  `yt-dlp --remux-video mkv`.

**PowerShell says "cannot find path" for `%APPDATA%`**
PowerShell uses `$env:APPDATA` instead of `%APPDATA%`.
