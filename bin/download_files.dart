import 'dart:async';
import 'dart:io';

import 'package:diox/diox.dart';

import 'src/constants.dart';

/// Url and progress.
final List<_Mission> _mQueue = <_Mission>[];

Future<void> main(List<String> arguments) async {
  await initializeCheck(arguments);
  await recoverDownloadedFiles();
  await sleep(5);
  runZonedGuarded(() => _handleQueue(), _postToBot);
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
  if (lines.isEmpty) {
    return;
  }
  final url = lines.removeAt(0);
  if (_mQueue.any((m) => m.url == url)) {
    return;
  }
  if (_mQueue.length >= maxQueue) {
    return;
  }
  _mQueue.add(_Mission(url: url));
  _download(url);
  _printQueue();
}

Future<void> _download(String url) async {
  final uri = Uri.parse(url);
  final filename = uri.queryParameters[filenameParameter]!;

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
  addToWritingQueue(url);

  _mQueue.removeWhere((m) => m.url == url);
  finishedCount++;
  if (finishedCount == totalCount) {
    print('All files are downloaded.');
    exit(0);
  }
  _addToQueue();
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

  // ignore: no_leading_underscores_for_local_identifiers
  void _print(Object v) {
    _lastLines++;
    print('$clearLine_$v\n');
  }

  if (_lastLines > 0) {
    print(clearLineAndUp(_lastLines));
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

const String _hideCursor = '\x1b[?25l';
const String _blockFilled_ = '█';
const String _blockEmpty_ = '▁';

const String botUrl = 'https://open.feishu.cn/open-apis/bot/v2/hook/'
    'feff0216-78f6-406a-ae7d-7459e3a4a6ac';

class _Mission {
  _Mission({required this.url});

  final String url;
  int progress = 1;
  double bytesPerSecond = 0;

  int _lastTime = ts;
  int _lastBytes = 0;

  void calculateSpeed(int count) {
    final now = ts;
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
        other is _Mission &&
            runtimeType == other.runtimeType &&
            url == other.url &&
            progress == other.progress;
  }

  @override
  int get hashCode => url.hashCode ^ progress.hashCode;
}
