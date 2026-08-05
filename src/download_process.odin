package main

import "core:fmt"
import "core:os"

// TODO:

// Get_Cleaned_Filename :: proc(fname: string) -> (cname: string, ok: bool) {
// 	no_suff := strings.trim_suffix(fname, ".mp3")
// 	bname := strings.clone(no_suff)
// 	defer delete_string(bname)
// 	if bname == fname do return "", false
//
// 	for toStrip in CONFIG.strip_from_file_name {
// 		was_alloc: bool
// 		tn := strings.clone(bname)
// 		delete_string(bname)
// 		bname, was_alloc = strings.remove_all(bname, toStrip)
// 		delete_string(tn)
// 	}
//
// 	return strings.clone(bname), true
// }

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

	if len(stderr) > 0 do fmt.printfln("ERR:\n%s", string(stderr))

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

	rm_err := os.remove_all(d.tmp_dir)
	if rm_err != nil do fmt.eprintfln("[ERROR] Failed to remove %s: %v", d.tmp_dir, rm_err)

	fmt.printfln("[INFO] Download complete: Files copied to [%s]", d.data^.output_destination)
	return true
}
