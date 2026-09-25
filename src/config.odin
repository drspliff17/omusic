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

Config_File_Cleanup :: struct {
	enable_file_name_cleanup:  bool,
	strip_from_file_name:      []string,
	use_underscore_for_spaces: bool,
}

Config_Meta_Tags :: struct {
	always_use_file_name:           bool,
	always_use_directory_name:      bool,
	always_use_working_directory:   bool,
	replace_underscores_for_spaces: bool,
}

Config :: struct {
	allow_make_destination:     bool,
	enable_logging:             bool,
	send_browser_cookies:       bool,
	default_download_directory: string,
	log_filepath:               string,
	browser_for_cookies:        string,
	custom_temp_location:       string,
	using meta_tag_config:      Config_Meta_Tags,
	using file_cleanup_config:  Config_File_Cleanup,
}

// Create default config file, or early return if it already exists
Config_Create_File :: proc() -> Config_Error {
  if !os.exists(CONFIG_DIRECTORY) do os.make_directory_all(CONFIG_DIRECTORY) or_return
	if os.exists(CONFIG_FILEPATH) do return nil

	usr_music := os.user_music_dir(context.allocator) or_return
	defer delete_string(usr_music)

	log := os.join_path({CONFIG_DIRECTORY, "omusic.log"}, context.allocator) or_return
	defer delete_string(log)

	default := Config {
		file_cleanup_config = {
			strip_from_file_name = []string{".", ",", "/", "?", "!", "\"", "'", "`"},
			enable_file_name_cleanup = true,
			use_underscore_for_spaces = true,
		},
		replace_underscores_for_spaces = true,
		default_download_directory = usr_music,
		log_filepath = log,
		enable_logging = true,
	}

	json_bytes := json.marshal(default) or_return
	defer delete_slice(json_bytes)

	os.write_entire_file_from_bytes(CONFIG_FILEPATH, json_bytes) or_return
	return nil
}

// Unmarshal Config File into CONFIG
Config_Load_From_File :: proc(c: ^Config) -> Config_Error {
	if !os.exists(CONFIG_FILEPATH) do fmt.panicf("[ERROR] Tried to load non-existant config file")

	data_bytes := os.read_entire_file_from_path(CONFIG_FILEPATH, context.allocator) or_return
	defer delete_slice(data_bytes)

	json.unmarshal(data_bytes, c) or_return
	return nil
}

// Conditional checks on Unmarshalled CONFIG data
Config_Ensure_Valid :: proc(c: ^Config) -> bool {
	if c.enable_file_name_cleanup {
		if len(c.strip_from_file_name) == 0 do Log(.WARN, "enable_file_name_cleanup is true, but strip_from_file_name array is empty", false)
	} else {
		if c.use_underscore_for_spaces do Log(.WARN, "use_underscore_for_spaces is true, but enable_file_name_cleanup set to false", false)
	}

	if len(c.default_download_directory) == 0 {
		if !c.always_use_working_directory do Log(.WARN, "default_download_directory is unset, and always_use_working_directory set to false", false)
	} else {
		if !os.exists(c.default_download_directory) && !c.always_use_working_directory {
			fmt.eprintfln(
				"[ERROR] Default Download Directory is not a valid path: %s",
				c.default_download_directory,
			)
			return false
		}
	}

	if c.send_browser_cookies && len(c.browser_for_cookies) == 0 {
		fmt.eprintln("[ERROR] send_browser_cookies set to true, but browser_for_cookies unset")
		return false
	}

	if c.enable_logging {
		if len(c.log_filepath) == 0 {
			fmt.eprintln("[ERROR] enable_logging set to true, but log_filepath unset")
			return false
		}
		if !os.exists(os.dir(c.log_filepath)) {
			fmt.eprintfln(
				"[ERROR] enable_logging set to true, but parent directory does not exist: %s",
				c.log_filepath,
			)
			return false
		}
	}

	if len(c.custom_temp_location) > 0 && !os.exists(c.custom_temp_location) {
		fmt.eprintfln(
			"[ERROR] custom_temp_location given [%s] - but directory does not exist",
			c.custom_temp_location,
		)
		return false
	}

	return true
}

// Config Destructor
Config_Delete :: proc(c: ^Config) {
	for str in c.strip_from_file_name do delete_string(str)
	delete_slice(c.strip_from_file_name)

	delete_string(c.custom_temp_location)
	delete_string(c.browser_for_cookies)
	delete_string(c.default_download_directory)
	delete_string(c.log_filepath)
}
