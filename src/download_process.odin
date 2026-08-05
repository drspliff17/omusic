package main

Download_Process_Job :: proc(d: ^Download_Job) {
	download_args := Construct_YtDlp_Args(d)
	defer delete_string(download_args)
}
