package main

import "core:encoding/json"
import "core:fmt"
import "core:mem"
import "core:os"

Config_Error :: union {
	mem.Allocator_Error,
	os.Error,
	json.Marshal_Error,
	json.Unmarshal_Error,
}

Config :: struct {
	strip_from_file_name:         []string,
	default_download_directory:   string,
	download_log_file_path:       string,
	browser_for_cookies:          string,
	send_browser_cookies:         bool,
	enable_download_logging:      bool,
	enable_file_name_cleanup:     bool,
	allow_make_destination:       bool,
	always_use_file_name:         bool,
	always_use_directory_name:    bool,
	always_use_working_directory: bool,
}

Config_Create_File :: proc() -> Config_Error {
	if os.exists(CONFIG_FILEPATH) {
		if DEBUG {
			os.remove(CONFIG_FILEPATH) or_return
		} else {
			return nil
		}
	}

	if !os.exists(CONFIG_DIRECTORY) {
		os.make_directory_all(CONFIG_DIRECTORY) or_return
	}

	usr_music := os.user_music_dir(context.allocator) or_return
	defer delete_string(usr_music)

	dwn_log := os.join_path({CONFIG_DIRECTORY, "downloads.log"}, context.allocator) or_return
	defer delete_string(dwn_log)

	default := Config {
		strip_from_file_name       = []string{".", ",", "/", "?", "!", "\"", "'", "`"},
		default_download_directory = usr_music,
		download_log_file_path     = dwn_log,
		enable_download_logging    = true,
	}

	json_bytes := json.marshal(default) or_return
	defer delete_slice(json_bytes)

	os.write_entire_file_from_bytes(CONFIG_FILEPATH, json_bytes) or_return
	return nil
}

Config_Load_From_File :: proc(c: ^Config) -> Config_Error {
	if !os.exists(CONFIG_FILEPATH) do fmt.panicf("[ERROR] Tried to load non-existant config file")

	data_bytes := os.read_entire_file_from_path(CONFIG_FILEPATH, context.allocator) or_return
	defer delete_slice(data_bytes)

	json.unmarshal(data_bytes, c) or_return
	return nil
}

Config_Ensure_Valid :: proc(c: ^Config) -> bool {
	if c.enable_file_name_cleanup && len(c.strip_from_file_name) == 0 do fmt.println("[WARNING] Filename cleanup enabled, but strip_from_file_name array is empty")

	if len(c.default_download_directory) == 0 {
		if !c.always_use_working_directory do fmt.println("[WARNING] Default download directory is unset")
	} else {
		if !os.exists(c.default_download_directory) {
			fmt.eprintfln(
				"[ERROR] Default Download Directory is not a valid path: %s",
				c.default_download_directory,
			)
			return false
		}
	}

	if c.send_browser_cookies && len(c.browser_for_cookies) == 0 {
		fmt.eprintln("[ERROR] Send Browser Cookies enabled, but Browser For Cookies unset")
		return false
	}

	if c.enable_download_logging && len(c.download_log_file_path) == 0 {
		fmt.eprintln("[ERROR] Download Logging Enabled, but Download Log Filepath unset")
		return false
	}

	return true
}

Config_Delete :: proc(c: ^Config) {
	for str in c.strip_from_file_name do delete_string(str)
	delete_slice(c.strip_from_file_name)

	delete_string(c.browser_for_cookies)
	delete_string(c.default_download_directory)
	delete_string(c.download_log_file_path)
}
