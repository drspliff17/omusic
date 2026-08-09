package main

import "core:fmt"
import "core:os"
import "core:strings"

Download_Data :: struct {
	download_url:       string,
	output_destination: string,
	tag_artist:         string,
	tag_album:          string,
	tag_title:          string,
}

// Constructor
Download_Data_Create :: proc() -> ^Download_Data {
	d, err := new(Download_Data)
	if err != nil do fmt.panicf("[ERROR] Failed to allocate Download_Data: %v", err)
	return d
}

// Destructor
Download_Data_Delete :: proc(d: ^Download_Data) {
	if len(d.download_url) > 0 do delete_string(d.download_url)
	if len(d.output_destination) > 0 do delete_string(d.output_destination)
	if len(d.tag_artist) > 0 do delete_string(d.tag_artist)
	if len(d.tag_album) > 0 do delete_string(d.tag_album)
	if len(d.tag_title) > 0 do delete_string(d.tag_title)
	free(d)
}

// Checks the bare minimum requirements are satisfied
Download_Data_Verify_Min :: proc(d: ^Download_Data) -> bool {
	if len(d.download_url) == 0 {
		fmt.eprintln("[ERROR] Invalid Download Data: Expected URL")
		return false
	} else {
		expected_format := "https://music.youtube.com/playlist"
		if !strings.starts_with(d.download_url, expected_format) {
			fmt.eprintfln(
				"[ERROR] Invalid Download_Data: URL expected to start with [%s]",
				expected_format,
			)
			return false
		}
	}

	if !CONFIG.always_use_working_directory {
		if len(d.output_destination) == 0 {
			fmt.eprintln("[ERROR] Invalid Download Data: Expected Output Directory")
			return false
		} else {
			if !os.exists(d.output_destination) && !CONFIG.allow_make_destination {
				fmt.eprintfln(
					"[ERROR] Invalid Download Data: Output Directory does not exist: [%s]",
					d.output_destination,
				)
				return false
			}
		}
	}

	return true
}
