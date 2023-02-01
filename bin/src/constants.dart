///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2022/1/4 10:43
///
import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

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
int finishedCount = 0;

const int maxQueue = 10;
final List<String> downloadedQueue = <String>[];
final List<String> writingQueue = <String>[];

int get ts => DateTime.now().millisecondsSinceEpoch;

void print(Object object) => stdout.write(object);

Future<void> sleep(int seconds) =>
    Future<void>.delayed(Duration(seconds: seconds));

late final Dio dio = Dio(
  BaseOptions(
    connectTimeout: 15000,
    receiveDataWhenStatusError: true,
  ),
);

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
  lines = await downloadFile.readAsLines();
  lines.removeWhere((String e) => e.isEmpty);
  totalCount = lines.length;
  print('$totalCount records found.\n');
}

Future<void> recoverDownloadedFiles({
  void Function(String url)? onNotFinished,
}) async {
  if (downloadedRecordsFile.existsSync()) {
    final list = (await downloadedRecordsFile.readAsString()).split('\n');
    finishedCount += list.length;
    for (final url in list) {
      lines.remove(url);
    }
  } else {
    await downloadedRecordsFile.create();
    final List<String> _lines = List<String>.of(lines);
    int _start = 0;
    print('\n');
    while (_start < totalCount) {
      if (downloadedQueue.length == maxQueue) {
        continue;
      }
      print(clearLineAndUp());
      print(clearLine_ + 'Checking downloaded file $_start...' + '\n');
      final url = _lines[_start];
      downloadedQueue.add(url);
      _start++;
      if (await _fileDownloaded(url, onNotFinished: onNotFinished)) {
        await addToWritingQueue(url);
        lines.remove(url);
        finishedCount++;
      }
      downloadedQueue.remove(url);
      if (_start == _lines.length - 1) {
        break;
      }
    }
  }
}

Future<bool> _fileDownloaded(
  String url, {
  void Function(String url)? onNotFinished,
}) async {
  final uri = Uri.parse(url);
  final filename = uri.queryParameters[filenameParameter]!;
  final File file = File('$downloadFolder/$filename');

  bool downloaded = false;
  if (file.existsSync()) {
    final int contentLength = await _obtainContentLength(url);
    final int fileBytesLength = await file.length();
    downloaded = fileBytesLength == contentLength;
    if (!downloaded) {
      onNotFinished?.call(url);
    }
  }
  return downloaded;
}

Future<int> _obtainContentLength(String url) async {
  try {
    final response = await dio.head(url);
    final _cv = response.headers.value(Headers.contentLengthHeader) as String;
    return int.parse(_cv);
  } catch (e) {
    return 0;
  }
}

Future<void> addToWritingQueue(String url) async {
  final bool isEmpty = writingQueue.isEmpty;
  writingQueue.add(url);
  if (isEmpty) {
    await handleWritingQueue();
  }
}

Future<void> handleWritingQueue() async {
  if (writingQueue.isNotEmpty) {
    final String url = writingQueue.first;
    await downloadedRecordsFile.writeAsString(
      '$url\n',
      mode: FileMode.append,
    );
    writingQueue.remove(url);
    if (writingQueue.isNotEmpty) {
      await handleWritingQueue();
    }
  }
}

const String clearLine_ = '\x1b[2K';

String clearLineAndUp([int line = 1]) {
  final String _lineWrap;
  if (line == 1) {
    _lineWrap = '\x1b[A';
  } else {
    _lineWrap = '\x1b[${line}A';
  }
  return clearLine_ + _lineWrap + clearLine_;
}
