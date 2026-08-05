package main

import "core:fmt"
import "core:mem"

DEBUG := true

main :: proc() {
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

	Globals_Init()
	defer Globals_Delete()

	cfg_create_err := Config_Create_File()
	if cfg_create_err != nil {
		fmt.eprintfln("[ERROR] Failed to create config file: %v", cfg_create_err)
		return
	}

	cfg_load_err := Config_Load_From_File(&CONFIG)
	if cfg_load_err != nil {
		fmt.eprintfln("[ERROR] Failed to load config file: %v", cfg_load_err)
		return
	}

	defer Config_Delete(&CONFIG)

	DOWNLOAD_MANAGER := Download_Manager_Create()
	defer Download_Manager_Delete(DOWNLOAD_MANAGER)


	// testM := Download_Manager_Create()
	// defer Download_Manager_Delete(testM)
	//
	// job := Download_Data_Create()
	// job.download_url = fmt.aprintf("example lol")
	// job.output_destination = fmt.aprintf("your ma's puss")
	// Download_Job_Create(job, testM)
	//
	// for j in testM.jobs do fmt.printfln("TEST:\n%v\n-------\n", j^)

}
