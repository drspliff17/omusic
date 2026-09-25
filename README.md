# omusic

A command-line YouTube Music playlist downloader written in Odin. It uses `yt-dlp`
to extract MP3 audio, and `eyeD3` to set ID3 tags, with optional filename cleanup
and batch downloads

**Note**: This is still WIP. Functional, but unfinished.

## Requirements

- Odin to build the project
- `yt-dlp` and `eyeD3` installed and available on your `PATH`
- `ffmpeg` for `yt-dlp`'s MP3 conversion

## Build

From the project directory:

```bash
odin build src -out:omusic
```

Then install somewhere on your path, i.e:

```bash
install -Dm755 omusic ~/.local/bin/omusic
```

## Usage

Download a YouTube Music playlist to an existing directory:

```bash
omusic -u "https://music.youtube.com/playlist?list=..." \
-o ~/Music -a "Artist" -A "Album" -ttf
```

Options are as follows:

```bash
-u  | --url
-o  | --output

-a  | --artist
-A  | --album
-t  | --title
-sc | --send-browser-cookies

-ttf | --tag-title-filename
-tad | --tag-artist-directory
-wd  | --use-working-directory
-mk  | --allow-mkdir-destination
```

### Required arguments

- `-u`
- `-o`: Note, only required if not using `-wd`, or `config.always_use_working_directory`

## Options

- `-sc <browser>`: Here for compatibility, sometimes `yt-dlp` will refuse to function
without this being set. Can be set with `config.browser_for_cookies` and
`config.send_browser_cookies`

### Flags

- `-ttf`: Derive each track's title from it's filename (post cleanup, if enabled)
- `-tad`: Derive the artist from the output directory name (replaces underscores
with spaces)
- `-wd`: Derive the output from the current working directory

### Job Files

For multiple playlists, you can create a json file containing an array of jobs:

```json
[
  {
    "download_url": "https://music.youtube.com/playlist?list=...",
    "output_destination": "/path/to/music",
    "tag_artist": "Artist",
    "tag_album": "Album"
  },
  {
    ...
  }
]
```

Then run:

```bash
omusic --slurp file.json
```

## Configuration

On first run, a default config is created at:

```bash
~/.config/omusic/config.json
```

You can control logging, filename cleanup, tag behaviour, browser cookies, and
temporary file locations. By default, logs are written to:

```bash
~/.config/omusic/omusic.log
```

**Note**: Only YouTube Music playlist urls are accepted. Output directories must
already exist for normal `-o` usage. `-wd` is an alternative
