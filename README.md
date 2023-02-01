# download_files

A simple command-line application to download a batch of files from the file.

## Getting started

1. Create your batch as a task directory under `tasks/` with the name, such as `tasks/20230201/`.
2. Place `files.txt` with all files URL separated with lines under your task directory.
3. `dart run bin/download_files.dart your_task_name`.

## Tools

- `check_duplicates.dart` can identify if your files in the task have duplicates.
- `generate_awaiting_files.dart` can generate files that haven't been downloaded with this tool.
- `recover_downloaded_files.dart` can recover the file list of downloaded files by scan them in the download folder.
