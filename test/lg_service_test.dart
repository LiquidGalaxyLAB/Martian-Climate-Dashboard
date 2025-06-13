import 'package:flutter_test/flutter_test.dart';
import 'package:martian_climate_dashboard/services/lg_service.dart';
import 'dart:typed_data';

class MockLgService extends LgService {
  List<String> executedCommands = [];
  List<Map<String, dynamic>> sentFiles = [];

  @override
  Future<LgService> execCommand(String command) async {
    executedCommands.add(command);
    return this;
  }

  @override
  Future<LgService> sendFile(String remoteFilepath, Uint8List content) async {
    sentFiles.add({'path': remoteFilepath, 'content': content});
    return this;
  }
}

void main() {
  group('LgService', () {
    late MockLgService service;

    setUp(() {
      service = MockLgService();
    });

    test('execCommand records command', () async {
      await service.execCommand('echo test');
      expect(service.executedCommands, contains('echo test'));
    });

    test('sendFile records file and content', () async {
      final data = Uint8List.fromList([1, 2, 3]);
      await service.sendFile('/tmp/test.txt', data);
      expect(service.sentFiles.first['path'], '/tmp/test.txt');
      expect(service.sentFiles.first['content'], data);
    });

    test('setRefresh calls execCommand for each rig', () async {
      service.rigs = 3;
      await service.setRefresh();
      expect(service.executedCommands.isNotEmpty, true);
    });

    test('resetRefresh calls execCommand for each rig', () async {
      service.rigs = 3;
      await service.resetRefresh();
      expect(service.executedCommands.isNotEmpty, true);
    });

    test('reboot calls execCommand for each rig', () async {
      service.rigs = 2;
      await service.reboot();
      expect(service.executedCommands.length, 2);
      expect(service.executedCommands[0], contains('reboot'));
    });

    test('relaunch calls execCommand for each rig', () async {
      service.rigs = 2;
      await service.relaunch();
      expect(service.executedCommands.isNotEmpty, true);
    });

    test('shutdown calls execCommand for each rig', () async {
      service.rigs = 2;
      await service.shutdown();
      expect(service.executedCommands.length, 2);
      expect(service.executedCommands[0], contains('poweroff'));
    });

    test('clearKml calls execCommand', () async {
      service.rigs = 3;
      await service.clearKml();
      expect(service.executedCommands.isNotEmpty, true);
      expect(service.executedCommands[0], contains('exittour=true'));
    });
  });
}
