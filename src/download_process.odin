package main

import "core:fmt"
import "core:os"


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
		//NOTE: Add log entry here
		fmt.eprintfln("[ERROR] Failed to download job [%s] -> dumping StdErr:\n", d.tmp_dir)
		fmt.eprintfln("%s", string(stderr))
		return false
	}

	if CONFIG.enable_file_name_cleanup {
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
			nn := Get_Stripped_Filename(file.name)
			defer delete_string(nn)

			new_path, err := os.join_path({os.dir(file.fullpath), nn}, context.allocator)
			if err != nil {
				fmt.eprintfln("[ERROR] Failed to allocate new_path:  [%s]: %v", file.fullpath, err)
				return false
			}
			defer delete_string(new_path)

			name_err := os.rename(file.fullpath, new_path)
			if name_err != nil {
				fmt.eprintfln(
					"[ERROR] Failed to move file [%s] to %s: %v",
					file.name,
					d^.data.output_destination,
					name_err,
				)
				return false
			}
		}
	}

	//TODO: Add meta tag process here

	copy_err := os.copy_directory_all(d.data^.output_destination, d.tmp_dir)
	if copy_err != nil {
		//NOTE: Add log entry here
		fmt.eprintfln("[ERROR] Failed to move finished job [%s]", d.tmp_dir)
		return false
	}

	rm_err := os.remove_all(d.tmp_dir)
	if rm_err != nil do fmt.eprintfln("[ERROR] Failed to remove %s: %v", d.tmp_dir, rm_err)

	fmt.printfln("[INFO] Download complete: Files copied to [%s]", d.data^.output_destination)
	return true
}
