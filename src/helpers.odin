package main

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"

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

// Returns allocated slice of arguments for job's eyeD3 Process_Desc (using CONFIG)
Construct_EyeD3_Args :: proc(d: ^Download_Job, alloc := context.allocator) -> []string {
	d_args := make([dynamic]string, alloc)
	defer {
		delete(d_args)
	}

	base := "eyeD3"
	append(&d_args, strings.clone(base, alloc))

	//TODO: FINISH LOGIC HERE

	return slice.clone(d_args[:], alloc)
}

//TODO: make this
Print_Help :: proc() {

}
