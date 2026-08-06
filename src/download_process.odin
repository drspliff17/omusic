package main

import "core:fmt"
import "core:os"


Download_Job_Clean_Files :: proc(d: ^Download_Job) -> bool {
	files, err := os.read_all_directory_by_path(d^.tmp_dir, context.allocator)
	defer {
		for f in files do os.file_info_delete(f, context.allocator)
		delete_slice(files)
	}
	if err != nil {
		fmt.eprintfln("[ERROR] Failed to read directory: %s: %v", d^.tmp_dir, err)
		return false
	}

	for f in files {

	}

	return true
}

// Main Download_Job proc
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
		file_info, fi_err := os.read_all_directory_by_path(d^.tmp_dir, context.allocator)
		if fi_err != nil {
			fmt.eprintfln("[ERROR] Failed to read directory: [%s]: %v", d^.tmp_dir, fi_err)
			return false
		}
		defer {
			for fi in file_info do os.file_info_delete(fi, context.allocator)
			delete_slice(file_info)
		}

		for file in file_info {
			fmt.printf("TEST: PRE:\t%s", file.name)
			nn := Get_Stripped_Filename(file.name)
			fmt.printfln("\t POST:\n%s", nn)
			delete_string(nn)
		}
	}

	//TODO: Add meta tag process here

	copy_err := os.copy_directory_all(d.data^.output_destination, d.tmp_dir)
	if copy_err != nil {
		//TODO: Add log entry here
		fmt.eprintfln("[ERROR] Failed to move finished job [%s]", d.tmp_dir)
		return false
	}

	rm_err := os.remove_all(d.tmp_dir)
	if rm_err != nil do fmt.eprintfln("[ERROR] Failed to remove %s: %v", d.tmp_dir, rm_err)

	fmt.printfln("[INFO] Download complete: Files copied to [%s]", d.data^.output_destination)
	return true
}
