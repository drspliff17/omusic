package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"

Log_Level :: enum {
	INFO,
	WARN,
	ERROR,
}

Log_Location :: enum {
	ALL,
	FILE,
	TTY,
}

Log :: proc(level: Log_Level, msg: string, msg_alloc: bool, location := Log_Location.ALL) {
	defer if msg_alloc do delete_string(msg)

	log, err := os.open(CONFIG.log_filepath, os.O_APPEND | os.O_WRONLY | os.O_CREATE)
	if err != nil do fmt.panicf("[ERROR] Failed to open log file: [%s]: %v", CONFIG.log_filepath, err)
	defer os.close(log)

	pre: string
	#partial switch (level) {
	case .WARN:
		pre = "[WARN]"
	case .ERROR:
		pre = "[ERROR]"
	case:
		pre = "[INFO]"
	}

	fmsg := strings.join({pre, msg}, " ")
	defer delete_string(fmsg)

	ts := time.now()
	date_bb: [time.MIN_YYYY_DATE_LEN]u8
	date := time.to_string_dd_mm_yyyy(ts, date_bb[:])

	time_bb: [time.MIN_HMS_LEN]u8
	t := time.time_to_string_hms(ts, time_bb[:])

	dt := strings.concatenate({"<", date, " ", ":", " ", t, ">"}, context.allocator)
	defer delete_string(dt)

	fstr := fmt.aprintfln("%s %s", dt, fmsg)
	defer delete_string(fstr)
	bytes := transmute([]u8)fstr

	switch (location) {

	case .ALL:
		written, write_err := os.write(log, bytes)
		if write_err != nil do fmt.panicf("[ERROR] Failed to write log: %v", write_err)

		switch (level) {
		case .ERROR, .WARN:
			fmt.eprintln(fmsg)

		case .INFO:
			fmt.println(fmsg)
		}

	case .FILE:
		written, write_err := os.write(log, bytes)
		if write_err != nil do fmt.panicf("[ERROR] Failed to write log: %v", write_err)

	case .TTY:
		switch (level) {
		case .ERROR, .WARN:
			fmt.eprintln(fmsg)

		case .INFO:
			fmt.println(fmsg)
		}

	}
}
