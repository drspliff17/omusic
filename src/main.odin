package main

import "core:fmt"
import "core:mem"

DEBUG_REMOVE_CONFIG := false
DEBUG_TRACK_ALLOC := false

main :: proc() {

	if DEBUG_TRACK_ALLOC {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("%v allocations not feed:\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			} else {
				fmt.println("TEST: No unfreed allocations")
			}

			if len(track.bad_free_array) > 0 {
				fmt.eprintf("%v incorrect free:\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %v bytes @ %v\n", entry.memory, entry.location)
				}
			} else {
				fmt.println("TEST: No bad free")
			}

			mem.tracking_allocator_destroy(&track)
		}
	}

	missing_dependancies := Check_Dependancies({"yt-dlp", "eyeD3"})
	defer {
		for m in missing_dependancies do delete_string(m)
		delete_slice(missing_dependancies)
	}
	if len(missing_dependancies) > 0 {
		fmt.eprintln("[ERROR] Failed Dependancy Check, could not find:")
		for m in missing_dependancies do fmt.eprintfln("\t-  %s", m)
		return
	}

	Globals_Init()
	defer Globals_Delete()

	if cfg_create_err := Config_Create_File(); cfg_create_err != nil {
		fmt.eprintfln("[ERROR] Failed to create config file: %v", cfg_create_err)
		return
	}

	if cfg_load_err := Config_Load_From_File(&CONFIG); cfg_load_err != nil {
		fmt.eprintfln("[ERROR] Failed to load config file: %v", cfg_load_err)
		return
	}

	defer Config_Delete(&CONFIG)

	if !Config_Ensure_Valid(&CONFIG) do return

	DOWNLOAD_MANAGER = Download_Manager_Create()
	defer Download_Manager_Delete(DOWNLOAD_MANAGER)

	manager_init := Download_Manager_Init_From_Args(DOWNLOAD_MANAGER)
	if !manager_init do return

	fmt.printfln("[INFO] Download Manager initialized with %d job(s)", len(DOWNLOAD_MANAGER.jobs))
	for job in DOWNLOAD_MANAGER.jobs do Download_Process_Job(job)
}
