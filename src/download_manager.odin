package main

import "core:fmt"

Download_Manager :: struct {
	jobs: [dynamic]^Download_Job,
}

Download_Manager_Create :: proc() -> ^Download_Manager {
	m, err := new(Download_Manager)
	if err != nil do fmt.panicf("[ERROR] Failed to allocate Download_Manager: %v", err)
	m.jobs = make([dynamic]^Download_Job)
	return m
}

Download_Manager_Delete :: proc(d: ^Download_Manager) {
	for job in d.jobs {
		delete_string(job.tmp_dir)
		Download_Data_Delete(job.data)
		free(job.data)
		free(job)
	}
	delete(d.jobs)
	free(d)
}
