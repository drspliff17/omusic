package main

import "core:strings"

Get_Stripped_Filename :: proc(file_name: string, alloc := context.allocator) -> string {
	base := strings.clone(strings.trim_suffix(file_name, ".mp3"), alloc)
	defer delete_string(base, alloc)

	new_name: string
	if CONFIG.use_underscore_for_spaces {
		base_no_space, was_alloc := strings.replace_all(base, " ", "_", alloc)
		new_name = strings.clone(base_no_space, alloc)
		if was_alloc do delete_string(base_no_space)
	} else {
		new_name = strings.clone(base, alloc)
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
