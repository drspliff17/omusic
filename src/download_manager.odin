package main

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"

Download_Manager :: struct {
	jobs: [dynamic]^Download_Job,
}

// Constructor
Download_Manager_Create :: proc() -> ^Download_Manager {
	m, err := new(Download_Manager)
	if err != nil do fmt.panicf("[ERROR] Failed to allocate Download_Manager: %v", err)
	m.jobs = make([dynamic]^Download_Job)
	return m
}

// Destructor
Download_Manager_Delete :: proc(d: ^Download_Manager) {
	for job in d.jobs {
		// err := os.remove_all(job^.tmp_dir)
		// if err != nil do fmt.eprintfln("Failed to remove temp directory: %s", job^.tmp_dir)
		Download_Job_Delete(job)
	}
	delete(d.jobs)
	free(d)
}

// Initialises Download_Manager.jobs from os.args
Download_Manager_Init_From_Args :: proc(m: ^Download_Manager) -> (init_ok: bool) {
	args := os.args[1:]
	if len(args) == 0 {
		Print_Help()
		return false
	}

	// Slurp Mode
	switch (args[0]) {
	case "-s", "slurp", "--slurp":
		if len(args) < 2 {
			fmt.eprintln("[ERROR] Invalid usage: Expected filepath to slurp: omusic -s <filepath>")
			return false
		}

		if !os.exists(args[1]) {
			fmt.eprintfln("[ERROR] Invalid file path given: Does not exist: %s", args[1])
			return false
		}

		file_info, err := os.stat(args[1], context.allocator)
		if err != nil {
			fmt.eprintfln("[ERROR] Failed to stat: %s", args[1])
			return false
		}

		defer os.file_info_delete(file_info, context.allocator)
		if file_info.type != .Regular {
			fmt.eprintfln(
				"[ERROR] Invalid usage: Expected regular file, got: %v for %s",
				file_info.type,
				args[1],
			)
			return false
		}

		if !strings.ends_with(file_info.name, ".json") {
			fmt.eprintfln("[ERROR] Expected job file to be json, got: %s", file_info.name)
			return false
		}

		jobs := make([dynamic]Download_Data)
		defer {
			for &j in jobs {
				if len(j.download_url) > 0 do delete_string(j.download_url)
				if len(j.output_destination) > 0 do delete_string(j.output_destination)
				if len(j.tag_artist) > 0 do delete_string(j.tag_artist)
				if len(j.tag_album) > 0 do delete_string(j.tag_album)
				if len(j.tag_title) > 0 do delete_string(j.tag_title)
			}
			delete(jobs)
		}

		read_bytes, read_err := os.read_entire_file_from_path(
			file_info.fullpath,
			context.allocator,
		)
		if read_err != nil {
			fmt.eprintfln("[ERROR] Failed to read file [%s]: %v", file_info.fullpath, read_err)
			return false
		}
		defer delete_slice(read_bytes)

		m_err := json.unmarshal(read_bytes, &jobs)
		if m_err != nil {
			fmt.eprintfln("[ERROR] Failed to unmarshal file [%s]: %v", file_info.fullpath, m_err)
			return false
		}

		for j, i in jobs {
			test := Download_Data {
				output_destination = j.output_destination,
				download_url       = j.download_url,
				tag_album          = j.tag_album,
				tag_artist         = j.tag_artist,
				tag_title          = j.tag_title,
			}
			if !Download_Data_Verify_Min(&test) {
				return false
			}

			data := Download_Data_Create()

			data.output_destination = strings.clone(j.output_destination)
			data.download_url = strings.clone(j.download_url)
			data.tag_album = strings.clone(j.tag_album)
			data.tag_artist = strings.clone(j.tag_artist)
			data.tag_title = strings.clone(j.tag_title)


			Download_Job_Create(data, m)
		}

		return true
	}


	// Single Job
	url, output, artist, album, title: string
	defer {
		if len(url) > 0 do delete_string(url)
		if len(output) > 0 do delete_string(output)
		if len(artist) > 0 do delete_string(artist)
		if len(album) > 0 do delete_string(album)
		if len(title) > 0 do delete_string(title)
	}

	for len(args) > 0 {
		switch (args[0]) {

		case "-u", "url", "--url":
			if len(args) < 2 {
				fmt.eprintln("[ERROR] Invalid usage: Expected url: omusic -u <url>")
				return false
			}

			url = strings.clone(args[1])
			args = args[2:]

		case "-o", "out", "--output":
			if len(args) < 2 {
				fmt.eprintln("[ERROR] Invalid usage: Expected path: omusic -o <path>")
				return false
			}

			if !os.exists(args[1]) {
				fmt.eprintfln("[ERROR] Invalid file path given: Does not exist: %s", args[1])
				return false
			}

			file_info, err := os.stat(args[1], context.allocator)
			if err != nil {
				fmt.eprintfln("[ERROR] Failed to stat: %s: %v", args[1], err)
				return false
			}
			defer os.file_info_delete(file_info, context.allocator)

			if file_info.type != .Directory {
				fmt.eprintfln(
					"[ERROR] Invalid usage: Expected Directory, got: %v for %s",
					file_info.type,
					args[1],
				)
				return false
			}

			output = strings.clone(args[1])
			args = args[2:]

		case "-a", "art", "--artist":
			if len(args) < 2 {
				fmt.eprintln("[ERROR] Invalid usage: Expected artist")
				return false
			}

			artist = strings.clone(args[1])
			args = args[2:]

		case "-ab", "alb", "--album":
			if len(args) < 2 {
				fmt.eprintln("[ERROR] Invalid usage: Expected album")
				return false
			}

			album = strings.clone(args[1])
			args = args[2:]

		case "-t", "tit", "--title":
			if len(args) < 2 {
				fmt.eprintln("[ERROR] Invalid usage: Expected title")
				return false
			}

			title = strings.clone(args[1])
			args = args[2:]

		case "-ttf", "--tag-title-filename":
			CONFIG.always_use_file_name = true
			args = args[1:]

		case "-tad", "--tag-artist-directory":
			CONFIG.always_use_directory_name = true
			args = args[1:]

		case "-wd", "--use-working-directory":
			CONFIG.always_use_working_directory = true
			args = args[1:]

		case "-mk", "--allow-mkdir-destination":
			CONFIG.allow_make_destination = true
			args = args[1:]

		case "-sc", "--send-browser-cookies":
			max := len(args) <= 2 ? len(args) : 2
			switch (max) {
			case 1:
				if len(CONFIG.browser_for_cookies) == 0 {
					fmt.eprintln(
						"[ERROR] Invalid Usage: Expected browser, and none is provided from config",
					)
					return false
				} else {
					CONFIG.send_browser_cookies = true
					args = args[1:]
				}
			case 2:
				CONFIG.send_browser_cookies = true
				if len(CONFIG.browser_for_cookies) > 0 do delete_string(CONFIG.browser_for_cookies)
				CONFIG.browser_for_cookies = strings.clone(args[1])
				args = args[2:]
			}

		case:
			fmt.eprintfln("Unknown argument: %s", args[0])
			return false
		}
	}

	test := Download_Data {
		download_url       = url,
		output_destination = output,
		tag_album          = album,
		tag_artist         = artist,
		tag_title          = title,
	}
	if !Download_Data_Verify_Min(&test) {
		return false
	}

	job_data := Download_Data_Create()

	job_data.download_url = strings.clone(url)
	job_data.output_destination = strings.clone(output)
	job_data.tag_album = strings.clone(album)
	job_data.tag_artist = strings.clone(artist)
	job_data.tag_title = strings.clone(title)

	Download_Job_Create(job_data, DOWNLOAD_MANAGER)

	return true
}
