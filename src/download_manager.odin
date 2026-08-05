package main

import "core:fmt"
import "core:os"

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
		err := os.remove_all(job^.tmp_dir)
		if err != nil do fmt.eprintfln("Failed to remove temp directory: %s", job^.tmp_dir)
		Download_Job_Delete(job)
	}
	delete(d.jobs)
	free(d)
}
