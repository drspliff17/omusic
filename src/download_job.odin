package main

import "core:fmt"
import "core:os"
import "core:strings"

Download_Job :: struct {
	data:    ^Download_Data,
	tmp_dir: string,
}

// Constructs Download_Job, then appends to manager.jobs
Download_Job_Create :: proc(data: ^Download_Data, manager: ^Download_Manager) {
	tmp := Download_Job_Assign_Temp_Directory()
	defer delete_string(tmp)

	job, err := new(Download_Job)
	if err != nil do fmt.panicf("[ERROR] Failed to allocate Download_Job: %v", err)

	job.tmp_dir = strings.clone(tmp, context.allocator)
	job.data = data
	append(&manager.jobs, job)
}

// Destructor
Download_Job_Delete :: proc(job: ^Download_Job) {
	delete_string(job.tmp_dir)
	Download_Data_Delete(job.data)
	free(job)
}

Download_Job_Assign_Temp_Directory :: proc() -> string {
	dir: string

	// override_dir, o_found := os.lookup_env("TMPDIR", context.allocator)
	// defer if o_found do delete_string(override_dir)

	if len(CONFIG.custom_temp_location) > 0 {
		if !os.exists(CONFIG.custom_temp_location) {
			fmt.eprintfln(
				"[ERROR] custom_temp_location is set, but does not exist: %s",
				CONFIG.custom_temp_location,
			)
		} else {
			// TODO: Dir check
			dir = CONFIG.custom_temp_location
		}
	}

	// if o_found {
	// 	if os.exists(override_dir) {dir = override_dir} else {
	// 		fmt.eprintfln("[ERROR] $TMPDIR is set, but does not exist: %s", override_dir)
	// 	}
	// }

	tmp, err := os.make_directory_temp(dir, "omusic_", context.allocator)
	if err != nil do fmt.panicf("Failed to create temp directory: %v", err)
	return tmp
}
