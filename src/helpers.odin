package main

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"

Check_Dependancies :: proc() -> (missing_deps: []string) {
	cmd: string
	when ODIN_OS == .Windows {
		cmd = "where"
	} else {
		cmd = "which"
	}

	reqs := []string{"yt-dlp", "eyeD3"}
	missing := make([dynamic]string)
	defer delete(missing)

	for r in reqs {
		args := []string{cmd, r}
		pd := os.Process_Desc {
			command = args,
		}
		state, stdout, stderr, err := os.process_exec(pd, context.allocator)
		if err != nil do fmt.panicf("[ERROR] Failed to run dependancy check: [%s]", r)
		defer {
			delete_slice(stdout)
			delete_slice(stderr)
		}
		if state.exit_code != 0 do append(&missing, strings.clone(r))
	}
	return slice.clone(missing[:], context.allocator)
}

Construct_YtDlp_Args :: proc(d: ^Download_Job) -> []string {
	d_args := make([dynamic]string)
	defer delete(d_args)

	append(&d_args, strings.clone("yt-dlp"))
	append(&d_args, strings.clone("-x"))
	append(&d_args, strings.clone("--audio-format"))
	append(&d_args, strings.clone("mp3"))
	append(&d_args, strings.clone(d.data^.download_url))

	if CONFIG.send_browser_cookies {
		append(&d_args, strings.clone("--cookies-from-browser"))
		append(&d_args, strings.clone(CONFIG.browser_for_cookies))
	}

	return slice.clone(d_args[:], context.allocator)
}

Construct_EyeD3_Args :: proc(d: ^Download_Job) -> []string {
	d_args := make([dynamic]string)
	defer {
		delete(d_args)
	}

	base := "eyeD3"
	append(&d_args, strings.clone(base))

	//TODO: FINISH LOGIC HERE

	return slice.clone(d_args[:], context.allocator)
}

Print_Help :: proc() {

}
