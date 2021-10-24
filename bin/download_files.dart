import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

const int maxQueue = 5;
const String downloadFolder = 'download';
const String downloadedRecords = 'downloaded_videos.txt';
const String filenameParameter = 'download_name';

/// Url and progress.
final List<_M> _mQueue = <_M>[];

Future<void> main(List<String> arguments) async {
  if (!Directory(downloadFolder).existsSync()) {
    Directory(downloadFolder).createSync();
  }
  final file = File('video.txt');
  lines = await file.readAsLines();
  totalCount = lines.length;
  print('$totalCount records found.');
  await _recoverDownloadedFiles();
  runZonedGuarded(() => _handleQueue(), (Object e, StackTrace s) async {
    await sleep(3);
    _postToBot(e, s);
    _handleQueue();
  });
}

Future<void> _recoverDownloadedFiles() async {
  final file = File(downloadedRecords);
  if (file.existsSync()) {
    final list = await file.readAsLines();
    finishedCount += list.length;
    for (final url in list) {
      lines.remove(url);
    }
  } else {
    await file.create();
    await Future.wait(List.generate(
      lines.length,
      (index) async {
        final url = lines[index];
        if (await _fileDownloaded(url)) {
          await file.writeAsString(url, mode: FileMode.append);
          lines.remove(url);
        }
      },
    ));
  }
}

Future<bool> _fileDownloaded(String url) async {
  final uri = Uri.parse(url);
  final filename = uri.queryParameters[filenameParameter]!;
  final File file = File('$downloadFolder/$filename');

  bool downloaded = false;
  if (file.existsSync()) {
    final int contentLength = await _obtainContentLength(url);
    final int fileBytesLength = await file.length();
    downloaded = fileBytesLength == contentLength;
  }
  return downloaded;
}

void _handleQueue() {
  while (_mQueue.length < maxQueue) {
    if (finishedCount == totalCount) {
      print('All files are downloaded.');
      exit(0);
    }
    _addToQueue();
  }
}

void _addToQueue() {
  final url = lines.removeAt(0);
  if (_mQueue.any((m) => m.url == url)) {
    return;
  }
  if (_mQueue.length >= maxQueue) {
    return;
  }
  _mQueue.add(_M(url: url));
  _download(url);
  _printQueue();
}

Future<void> _download(String url) async {
  final uri = Uri.parse(url);
  final filename = uri.queryParameters[filenameParameter]!;

  try {
    await dio.download(
      url,
      '$downloadFolder/$filename',
      onReceiveProgress: (int count, int total) {
        _mQueue.singleWhere((m) => m.url == url)
          ..progress = count * 100 ~/ total
          ..calculateSpeed(count);
        _printQueue();
      },
    );
    await File(downloadedRecords).writeAsString(
      '$url\n',
      mode: FileMode.append,
    );
  } catch (e) {
    await _download(url);
    return;
  }

  _mQueue.removeWhere((m) => m.url == url);
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
  final String content;
  if (e is DioError) {
    content = '${e.requestOptions.uri} ${e.message} ${e.type}';
  } else {
    content = '$e, $s';
  }
  await dio.post(botUrl, data: {
    'msg_type': 'text',
    'content': {
      'text': content.replaceAll('"', r'\"'),
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
  for (final m in _mQueue) {
    final filename =
        Uri.parse(m.url).queryParameters[filenameParameter] as String;
    _print(' - $filename');
    final int p = m.progress ~/ 2;
    _print(
      '   '
      '${_blockFilled_ * p + _blockEmpty_ * (50 - p)}  '
      '${m.speed}',
    );
    _print('');
  }
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

int get _ts => DateTime.now().millisecondsSinceEpoch;

void print(Object object) {
  stdout.write(object);
}

Future<void> sleep(int seconds) {
  return Future<void>.delayed(Duration(seconds: seconds));
}

class _M {
  _M({
    required this.url,
    this.progress = 1,
  });

  final String url;
  int progress;
  double bytesPerSecond = 0;

  int _lastTime = _ts;
  int _lastBytes = 0;

  void calculateSpeed(int count) {
    final now = _ts;
    if (now - _lastTime < 500) {
      return;
    }
    if (_lastTime > 0) {
      final diff = (count - _lastBytes).abs();
      final duration = now - _lastTime;
      bytesPerSecond = diff / duration;
    }
    _lastTime = now;
    _lastBytes = count;
  }

  String get speed {
    String unit;
    double speed;
    if (bytesPerSecond >= 1000) {
      speed = bytesPerSecond / 1024;
      unit = 'Mb';
    } else {
      speed = bytesPerSecond;
      unit = 'Kb';
    }
    return '${speed.toStringAsFixed(2)} $unit/s';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _M &&
            runtimeType == other.runtimeType &&
            url == other.url &&
            progress == other.progress;
  }

  @override
  int get hashCode => url.hashCode ^ progress.hashCode;
}
