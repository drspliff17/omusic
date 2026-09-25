package main

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"

// Returns the number of .mp3 files in given directory
Get_MP3_Count :: proc(directory: string) -> int {
	c := 0
	fi, fi_err := os.read_all_directory_by_path(directory, context.allocator)
	defer os.file_info_slice_delete(fi, context.allocator)
	if fi_err != nil {
		fmt.panicf(
			"[ERROR] Failed to read contents of output directory [%s]: %v",
			directory,
			fi_err,
		)
	}
	for file in fi {
		if strings.has_suffix(file.name, ".mp3") do c += 1
	}
	return c
}

// Check if given requirements are found, returns slice of missing deps
Check_Dependancies :: proc(
	reqs: []string,
	alloc := context.allocator,
) -> (
	missing_deps: []string,
) {

	cmd: string
	when ODIN_OS == .Windows {
		cmd = "where"
	} else {
		cmd = "which"
	}

	missing := make([dynamic]string, alloc)
	defer delete(missing)

	for r in reqs {
		args := []string{cmd, r}
		pd := os.Process_Desc {
			command = args,
		}
		state, stdout, stderr, err := os.process_exec(pd, alloc)
		if err != nil do fmt.panicf("[ERROR] Failed to run dependancy check: [%s]", r)
		defer {
			delete_slice(stdout, alloc)
			delete_slice(stderr, alloc)
		}
		if state.exit_code != 0 do append(&missing, strings.clone(r, alloc))
	}
	return slice.clone(missing[:], alloc)
}


Print_Help :: proc() {
	h := fmt.aprintf(
		`
          omusic
============================
Arguments:
-u  | --url
-o  | --output

-a  | --artist
-A  | --album
-t  | --title
-sc | --send-browser-cookies

Flags:
-ttf | --tag-title-filename
-tad | --tag-artist-directory
-wd  | --use-working-directory
-mk  | --allow-mkdir-destination

Config file: %s

For more information, see:
man omusic
`,
		CONFIG_FILEPATH,
	)
	fmt.println(h)
	delete_string(h)
}
