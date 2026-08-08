package main

import "core:fmt"
import "core:os"
import "core:strings"


// Main Download_Job proc
Download_Process_Job :: proc(d: ^Download_Job) -> bool {
	defer {
		rm_err := os.remove_all(d.tmp_dir)
		if rm_err != nil do Log(.ERROR, fmt.aprintf("Failed to remove directory [%s]: %v", d.tmp_dir, rm_err), true)
	}

	// Override from CONFIG
	if CONFIG.always_use_working_directory {
		wd, err := os.get_working_directory(context.allocator)
		if err != nil do fmt.panicf("[ERROR] Failed to get working directory: %v", err)
		d^.data.output_destination = wd
	}

	if len(d^.data^.download_url) == 0 {
		Log(.ERROR, "Expected playlist url to download", false, .TTY)
		return false
	} else {
		expected_format := "https://music.youtube.com/playlist"
		if !strings.starts_with(d^.data^.download_url, expected_format) {
			Log(
				.ERROR,
				fmt.aprintf("Invalid url, expected to start with:\n\t%s", expected_format),
				true,
				.TTY,
			)
			return false
		}
	}

	if len(d^.data^.output_destination) == 0 {
		Log(.ERROR, "Expected output destination", false, .TTY)
		return false
	} else {

		if !os.exists(d^.data^.output_destination) {
			if CONFIG.allow_make_destination {
				err := os.make_directory_all(d^.data^.output_destination)
				if err != nil {
					Log(.ERROR, fmt.aprintf("Failed to create output directory: %v", err), true)
					return false
				}
			} else {
				Log(
					.ERROR,
					fmt.aprintf(
						"Given output directory does not exist: %s\nTo allow output destination to be created - see config:allow_make_destination",
						d^.data^.output_destination,
					),
					true,
					.TTY,
				)
				return false
			}
		}

	}

	pre_download_output_mp3_count := Get_MP3_Count(d^.data^.output_destination)

	// Download
	download_args := Construct_YtDlp_Args(d)
	defer {
		for a in download_args do delete_string(a)
		delete_slice(download_args)
	}

	Log(.INFO, fmt.aprintf("Download starting (Output: %s)", d^.data^.output_destination), true)

	pd := os.Process_Desc {
		command     = download_args[:],
		working_dir = d.tmp_dir,
	}

	_, stdout, stderr, err := os.process_exec(pd, context.allocator)
	defer {
		delete_slice(stdout)
		delete_slice(stderr)
	}

	if err != nil {
		Log(
			.ERROR,
			fmt.aprintf(
				"Unexpected download process error: (Output: %s)",
				d^.data^.output_destination,
			),
			true,
		)
		Log(.ERROR, fmt.aprintf("Dumping stderr:\n%s", string(stderr)), true, .TTY)

		return false
	}

	// File Cleanup
	if CONFIG.enable_file_name_cleanup {
		file_info, fi_err := os.read_all_directory_by_path(d^.tmp_dir, context.allocator)
		if fi_err != nil {
			Log(
				.ERROR,
				fmt.aprintf("Failed to read directory: [%s]: %v", d^.tmp_dir, fi_err),
				true,
			)
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
				Log(
					.ERROR,
					fmt.aprintf("Failed to allocate new path: [%s]: %v", file.fullpath, err),
					true,
				)
				return false
			}
			defer delete_string(new_path)

			name_err := os.rename(file.fullpath, new_path)
			if name_err != nil {
				Log(
					.ERROR,
					fmt.aprintf(
						"Failed to move file: [%s] to %s: %v",
						file.name,
						d^.data.output_destination,
						name_err,
					),
					true,
				)
				return false
			}
		}
	}

	// Clear && Set Meta-Tags
	file_info, file_err := os.read_all_directory_by_path(d^.tmp_dir, context.allocator)
	if file_err != nil {
		Log(.ERROR, fmt.aprintf("Failed to read directory: [%s]: %v", d^.tmp_dir, file_err), true)
		return false
	}
	defer {
		for fi in file_info do os.file_info_delete(fi, context.allocator)
		delete_slice(file_info)
	}

	for file in file_info {

		// Override Tags
		//NOTE: Maybe add some kind of check for if tag is already set

		if CONFIG.always_use_file_name {
			no_ext := strings.trim_suffix(file.name, ".mp3")
			if CONFIG.replace_underscores_for_spaces {
				conv, was_alloc := strings.replace_all(no_ext, "_", " ")
				defer if was_alloc do delete_string(conv)
				d^.data.tag_title = strings.clone(conv)
			} else {
				d^.data.tag_title = strings.clone(no_ext)
			}
		}

		if CONFIG.always_use_directory_name {
			dir := os.base(d^.data.output_destination)
			if CONFIG.replace_underscores_for_spaces {
				conv, was_alloc := strings.replace_all(dir, "_", " ")
				defer if was_alloc do delete_string(conv)
				d^.data.tag_artist = strings.clone(conv)
			} else {
				d^.data.tag_artist = strings.clone(dir)
			}
		}

		clear := os.Process_Desc {
			command = []string{"eyeD3", "--remove-all", file.fullpath},
		}

		_, stdout, stderr, err := os.process_exec(clear, context.allocator)
		delete_slice(stdout)
		delete_slice(stderr)
		if err != nil do Log(.ERROR, fmt.aprintf("Failed to clear tags from %s: %v", file.fullpath, err), true)

		args := Construct_EyeD3_Full_Args(d, file.name)
		defer {
			for a in args do delete_string(a)
			delete_slice(args)
		}

		set_tags := os.Process_Desc {
			working_dir = d^.tmp_dir,
			command     = args[:],
		}

		_, stdout, stderr, err = os.process_exec(set_tags, context.allocator)
		delete_slice(stdout)
		delete_slice(stderr)
		if err != nil do Log(.ERROR, fmt.aprintf("Failed to set tags for %s: %v", file.fullpath, err), true)

	}

	// Move and Cleanup
	copy_err := os.copy_directory_all(d.data^.output_destination, d.tmp_dir)
	if copy_err != nil {
		Log(.ERROR, fmt.aprintf("Failed to move finished job: %s: %v", d.tmp_dir, copy_err), true)
		return false
	}

	post_download_mp3_count := Get_MP3_Count(d^.data^.output_destination)
	if pre_download_output_mp3_count < post_download_mp3_count {
		Log(
			.INFO,
			fmt.aprintf("Download complete: Files copied to: %s", d.data^.output_destination),
			true,
		)
		return true
	} else {
		Log(
			.ERROR,
			"Process should have succeeded, but no new files detected in output directory - Try using -sc <browser>",
			false,
		)
		return false
	}
}
