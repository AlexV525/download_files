import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

const int maxQueue = 5;
const String downloadFolder = 'download';
const String filenameParameter = 'download_name';

/// Url and progress.
final Map<String, int> _urlsQueue = <String, int>{};

Future<void> main(List<String> arguments) async {
  if (!Directory(downloadFolder).existsSync()) {
    Directory(downloadFolder).createSync();
  }
  final file = File('video.txt');
  lines = await file.readAsLines();
  totalCount = lines.length;
  print('$totalCount records found.');
  runZonedGuarded(() => _handleQueue(), (Object e, StackTrace s) async {
    print(e);
    print(s);
    await sleep(3);
    _postToBot(e, s);
    _handleQueue();
  });
}

void _handleQueue() {
  while (_urlsQueue.length < maxQueue) {
    if (finishedCount == totalCount) {
      print('All done.');
      exit(0);
    }
    _addToQueue();
  }
}

void _addToQueue() {
  final url = lines.removeAt(0);
  if (_urlsQueue.containsKey(url)) {
    return;
  }
  if (_urlsQueue.length >= maxQueue) {
    return;
  }
  _urlsQueue[url] = 1;
  _download(url);
  _printQueue();
}

Future<void> _download(String url) async {
  final uri = Uri.parse(url);
  final filename = uri.queryParameters[filenameParameter]!;
  final File file = File('$downloadFolder/$filename');

  bool fileExist = false;
  if (file.existsSync()) {
    final int contentLength = await _obtainContentLength(url);
    final int fileBytesLength = file.lengthSync();
    fileExist = fileBytesLength == contentLength;
  }
  if (!fileExist) {
    try {
      await dio.download(
        url,
        '$downloadFolder/$filename',
        onReceiveProgress: (int count, int total) {
          _urlsQueue[url] = count * 100 ~/ total;
          _printQueue();
        },
      );
    } catch (e) {
      _download(url);
      return;
    }
  }

  _urlsQueue.remove(url);
  finishedCount++;
  if (finishedCount == totalCount) {
    print('All files are downloaded.');
    exit(0);
  }
  _addToQueue();
}

Future<int> _obtainContentLength(String url) async {
  final response = await dio.head(url);
  final _cv = response.headers.value(Headers.contentLengthHeader) as String;
  return int.parse(_cv);
}

Future<void> _postToBot(Object e, StackTrace s) async {
  await dio.post(botUrl, data: {
    'msg_type': 'text',
    'content': {
      'text': '$e, $s'.replaceAll('"', r'\"'),
    },
  });
}

int _lastLines = 0;

void _printQueue() {
  print(_hideCursor);
  void _print(Object v) {
    _lastLines++;
    print(_clearLine_ + v.toString() + '\n');
  }

  if (_lastLines > 0) {
    print(_clearLineAndUp(_lastLines));
  }
  _print('Downloading files:');
  final entries = _urlsQueue.entries;
  for (final entry in entries) {
    final filename = Uri.parse(
      entry.key,
    ).queryParameters[filenameParameter] as String;
    _print(' - $filename');
  }
  _print('');
  for (final entry in entries) {
    final int p = entry.value ~/ 2;
    _print('   ${_blockFilled_ * p + _blockEmpty_ * (50 - p)}');
  }
  _print('');
  _print(
    '${(finishedCount / totalCount * 100).toStringAsFixed(2)}%'
    ' | $finishedCount / $totalCount',
  );
}

late final int totalCount;
late List<String> lines;
int finishedCount = 0;

const String _hideCursor = '\x1b[?25l';
const String _clearLine_ = '\x1b[2K';
const String _blockFilled_ = '█';
const String _blockEmpty_ = '▁';

const String botUrl = 'https://open.feishu.cn/open-apis/bot/v2/hook/'
    'feff0216-78f6-406a-ae7d-7459e3a4a6ac';

String _clearLineAndUp([int line = 1]) {
  final String _lineWrap;
  if (line == 1) {
    _lineWrap = '\x1b[A';
  } else {
    _lineWrap = '\x1b[${line}A';
  }
  return _clearLine_ + _lineWrap + _clearLine_;
}

Dio get dio => Dio(BaseOptions(
      connectTimeout: 15000,
      sendTimeout: 15000,
      receiveDataWhenStatusError: true,
    ));

void print(Object object) {
  stdout.write(object);
}

Future<void> sleep(int seconds) {
  return Future<void>.delayed(Duration(seconds: seconds));
}
