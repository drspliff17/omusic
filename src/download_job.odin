package main

import "core:fmt"

Download_Job :: struct {
	data:    ^Download_Data,
	tmp_dir: string,
}

Download_Job_Create :: proc(data: ^Download_Data, manager: ^Download_Manager) {
	//TODO: ADD TMP DIRECTORY CREATION HERE

	job, err := new(Download_Job)
	if err != nil do fmt.panicf("[ERROR] Failed to allocate Download_Job: %v", err)

	job.data = data
	append(&manager.jobs, job)
}
