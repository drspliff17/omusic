package main

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"

// Check if given requirements are found, returns slice of missing deps
Check_Dependancies :: proc(
	reqs: []string,
	alloc := context.allocator,
) -> (
	missing_deps: []string,
) {

	cmd: string
	when ODIN_OS == .Windows {
		cmd = "where"
	} else {
		cmd = "which"
	}

	missing := make([dynamic]string, alloc)
	defer delete(missing)

	for r in reqs {
		args := []string{cmd, r}
		pd := os.Process_Desc {
			command = args,
		}
		state, stdout, stderr, err := os.process_exec(pd, alloc)
		if err != nil do fmt.panicf("[ERROR] Failed to run dependancy check: [%s]", r)
		defer {
			delete_slice(stdout, alloc)
			delete_slice(stderr, alloc)
		}
		if state.exit_code != 0 do append(&missing, strings.clone(r, alloc))
	}
	return slice.clone(missing[:], alloc)
}


//TODO: make this
Print_Help :: proc() {

}
