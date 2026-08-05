package main

import "core:fmt"
import "core:os"
import "core:strings"

HOME: string
CONFIG_DIRECTORY: string
CONFIG_FILEPATH: string

CONFIG: Config

Globals_Init :: proc() {
	home, config_dir, config_file: string
	err: os.Error

	home, err = os.user_home_dir(context.allocator)
	if err != nil do fmt.panicf("[ERROR] Failed to allocate User Home Directory: %v", err)
	HOME = strings.clone(home, context.allocator)
	delete_string(home)

	config_dir, err = os.join_path({HOME, ".config", "omusic2"}, context.allocator)
	if err != nil do fmt.panicf("[ERROR] Failed to allocate Config Directory: %v", err)
	CONFIG_DIRECTORY = strings.clone(config_dir, context.allocator)
	delete_string(config_dir)

	config_file, err = os.join_path({CONFIG_DIRECTORY, "config.json"}, context.allocator)
	if err != nil do fmt.panicf("[ERROR] Failed to allocate Config Filepath: %v", err)
	CONFIG_FILEPATH = strings.clone(config_file, context.allocator)
	delete_string(config_file)
}

Globals_Delete :: proc() {
	delete_string(HOME)
	delete_string(CONFIG_DIRECTORY)
	delete_string(CONFIG_FILEPATH)
}
