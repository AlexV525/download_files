///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2022/1/4 10:43
///
import 'dart:io';

late String task;
late String downloadFolder = 'download/$task';
late String downloadFileRecords = 'tasks/$task/files.txt';
late String downloadedFileRecords = 'tasks/$task/downloaded_files.txt';
late String awaitingFileRecords = 'tasks/$task/awaiting_files.txt';
late File downloadFile = File(downloadFileRecords);
late File downloadedRecordsFile = File(downloadedFileRecords);
late File awaitingRecordsFile = File(awaitingFileRecords);
const String filenameParameter = 'download_name';

late final int totalCount;
late List<String> lines;

Future<void> initializeCheck(List<String> arguments) async {
  if (arguments.isEmpty) {
    throw ArgumentError.notNull('Task');
  }
  task = arguments.first;
  if (!Directory('tasks/$task').existsSync()) {
    throw StateError('Task $task is not exist.');
  }
  if (!Directory(downloadFolder).existsSync()) {
    Directory(downloadFolder).createSync(recursive: true);
  }
  lines = (await downloadFile.readAsString()).split('\n');
  lines.removeWhere((String e) => e.isEmpty);
  totalCount = lines.length;
  print('$totalCount records found.');
}
