///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2022/1/4 14:18
///
import 'src/constants.dart';

final List<String> _notFinishedDownloadFiles = <String>[];

Future<void> main(List<String> arguments) async {
  await initializeCheck(arguments);
  await recoverDownloadedFiles(onNotFinished: _notFinishedDownloadFiles.add);
  print('Not finished:\n${_notFinishedDownloadFiles.join('\n')}');
}
