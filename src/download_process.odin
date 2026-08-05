package main

import "core:fmt"
import "core:os"

Download_Process_Job :: proc(d: ^Download_Job) -> bool {
	download_args := Construct_YtDlp_Args(d)
	defer {
		for a in download_args do delete_string(a)
		delete_slice(download_args)
	}

	pd := os.Process_Desc {
		command     = download_args[:],
		working_dir = d.tmp_dir,
	}

	state, stdout, stderr, err := os.process_exec(pd, context.allocator)
	defer {
		delete_slice(stdout)
		delete_slice(stderr)
	}

	if state.exit_code != 0 {
		//TODO: Add log entry here
		fmt.eprintfln("[ERROR] Failed to download job [%s] -> dumping StdErr:\n", d.tmp_dir)
		fmt.eprintfln("%s", string(stderr))
		return false
	}

	if CONFIG.enable_file_name_cleanup {
		//TODO: Add file cleanup process
	}

	//TODO: Add meta tag process here

	copy_err := os.copy_directory_all(d.data^.output_destination, d.tmp_dir)
	if copy_err != nil {
		//TODO: Add log entry here
		fmt.eprintfln("[ERROR] Failed to move finished job [%s]", d.tmp_dir)
		return false
	}

	fmt.printfln("[INFO] Download complete: Files copied to [%s]", d.data^.output_destination)
	return true
}
