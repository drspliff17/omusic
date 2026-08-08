package main

import "core:slice"
import "core:strings"

Get_Stripped_Filename :: proc(file_name: string, alloc := context.allocator) -> string {
	base := strings.clone(strings.trim_suffix(file_name, ".mp3"), alloc)
	defer delete_string(base, alloc)

	base_decoded: string
	if idx := strings.index(base, "["); idx >= 0 {
		base_decoded = base[:idx - 1]
	}
	if len(base_decoded) == 0 do base_decoded = base

	new_name: string
	if CONFIG.use_underscore_for_spaces {
		base_no_space, was_alloc := strings.replace_all(base_decoded, " ", "_", alloc)
		new_name = strings.clone(base_no_space, alloc)
		if was_alloc do delete_string(base_no_space)
	} else {
		new_name = strings.clone(base_decoded, alloc)
	}

	defer delete_string(new_name, alloc)
	for strip in CONFIG.strip_from_file_name {
		sn, was_alloc := strings.remove_all(new_name, strip, alloc)
		if was_alloc {
			delete_string(new_name, alloc)
			new_name = strings.clone(sn, alloc)
			delete_string(sn, alloc)
		}
	}
	final_name := strings.join({new_name, ".mp3"}, "", alloc)
	defer delete_string(final_name, alloc)

	return strings.clone(final_name, alloc)
}

// Returns allocated slice of arguments for job's yt-dlp Process_Desc (using CONFIG)
Construct_YtDlp_Args :: proc(d: ^Download_Job, alloc := context.allocator) -> []string {
	d_args := make([dynamic]string, alloc)
	defer delete(d_args)

	append(&d_args, strings.clone("yt-dlp", alloc))
	append(&d_args, strings.clone("-x", alloc))
	append(&d_args, strings.clone("--audio-format", alloc))
	append(&d_args, strings.clone("mp3", alloc))
	append(&d_args, strings.clone(d.data^.download_url, alloc))

	if CONFIG.send_browser_cookies {
		append(&d_args, strings.clone("--cookies-from-browser", alloc))
		append(&d_args, strings.clone(CONFIG.browser_for_cookies, alloc))
	}

	return slice.clone(d_args[:], alloc)
}

// Returns allocated slice of arguments for job's eyeD3 Process_Desc
Construct_EyeD3_Core_Args :: proc(d: ^Download_Job, alloc := context.allocator) -> []string {
	d_args := make([dynamic]string, alloc)
	defer delete(d_args)

	base := "eyeD3"
	append(&d_args, strings.clone(base, alloc))
	append(&d_args, strings.clone("--album", alloc))
	append(&d_args, strings.clone(d^.data^.tag_album, alloc))
	append(&d_args, strings.clone("--artist", alloc))
	append(&d_args, strings.clone(d^.data^.tag_artist, alloc))
	append(&d_args, strings.clone("--title", alloc))
	append(&d_args, strings.clone(d^.data^.tag_title, alloc))

	return slice.clone(d_args[:], alloc)
}

Construct_EyeD3_Full_Args :: proc(
	d: ^Download_Job,
	filename: string,
	alloc := context.allocator,
) -> []string {
	core := Construct_EyeD3_Core_Args(d, alloc)
	defer {
		delete_slice(core, alloc)
	}

	d_args := slice.clone_to_dynamic(core, alloc)
	defer delete(d_args)

	append(&d_args, strings.clone(filename, alloc))

	return slice.clone(d_args[:], alloc)
}
