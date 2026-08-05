package main

import "core:fmt"

Download_Data :: struct {
	download_url:       string,
	output_destination: string,
	tag_artist:         string,
	tag_album:          string,
	tag_title:          string,
}

Download_Data_Create :: proc() -> ^Download_Data {
	d, err := new(Download_Data)
	if err != nil do fmt.panicf("[ERROR] Failed to allocate Download_Data: %v", err)
	return d
}

Download_Data_Delete :: proc(d: ^Download_Data) {
	if len(d.download_url) > 0 do delete_string(d.download_url)
	if len(d.output_destination) > 0 do delete_string(d.output_destination)
	if len(d.tag_artist) > 0 do delete_string(d.tag_artist)
	if len(d.tag_album) > 0 do delete_string(d.tag_album)
	if len(d.tag_title) > 0 do delete_string(d.tag_title)
	free(d)
}
