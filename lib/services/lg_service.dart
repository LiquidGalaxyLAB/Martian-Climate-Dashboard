/// A service class for interacting with a Liquid Galaxy system over SSH.
///
/// Provides methods to:
/// - Check SSH connection to the LG master node.
/// - Execute commands remotely on LG nodes.
/// - Send files to LG nodes via SFTP.
/// - Manage refresh intervals for KML files on LG slaves.
/// - Reboot, relaunch, or shutdown the LG system.
/// - Clear KML files on LG slaves.
///
/// The class uses the `dartssh2` package for SSH and SFTP operations.
///
/// Example usage:
/// ```dart
/// final lgService = LgService();
/// await lgService.checkConnection();
/// await lgService.execCommand('ls');
/// ```
///
/// Properties:
/// - [host]: The IP address of the LG master node.
/// - [port]: The SSH port (default 22).
/// - [username]: SSH username (default 'lg').
/// - [password]: SSH password (default 'lg').
/// - [rigs]: Number of LG nodes (default 3).
///
/// Methods:
/// - [checkConnection]: Checks SSH connectivity to the master node.
/// - [execCommand]: Executes a shell command on the master node.
/// - [sendFile]: Sends a file to a remote path on the master node.
/// - [getClient]: Returns an authenticated SSH client.
/// - [setRefresh]: Enables periodic refresh for KML files on LG slaves.
/// - [resetRefresh]: Disables periodic refresh for KML files on LG slaves.
/// - [reboot]: Reboots all LG nodes.
/// - [relaunch]: Restarts the display manager on all LG nodes.
/// - [shutdown]: Powers off all LG nodes.
/// - [clearKml]: Clears KML files on LG slaves, optionally keeping logos.
library;

import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LgService {
  String host = "192.168.121.3";
  int port = 22;
  String username = "lg";
  String password = "lg";
  int rigs = 3;
  bool marsSelected = false;
  bool connected = false;
  SSHClient? _client;
  SftpClient? _sftp;
  final Map<String, String> _lastFileHash = {};
  Future<void> _fileQueue = Future.value();
  bool _connecting = false;

  int get logoScreen {
    if (rigs == 1) {
      return 1;
    }

    // Gets the most left screen.
    return (rigs / 2).floor() + 2;
  }

  int get balloonScreen {
    if (rigs == 1) {
      return 1;
    }

    // Gets the most right screen.
    return (rigs / 2).floor() + 1;
  }

  Future<bool> checkConnection() async {
    try {
      // print('Connecting to $host:$port...');
      final socket = await SSHSocket.connect(
        host,
        port,
        timeout: Duration(seconds: 5),
      );
      SSHClient(socket, username: username, onPasswordRequest: () => password);

      await clearKml();
      await changeToMars();
      await sendLogos();
      if (kDebugMode) {
        print('Connected to $host:$port');
      }
      connected = true;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to connect to $host:$port, $e');
      }
      connected = false;
      return false;
    }
  }

  Future<LgService> execCommand(String command) async {
    try {
      final socket = await SSHSocket.connect(host, port);
      final client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );
      SSHSession session = await client.execute(command);
      // print("stdout: ${session.stdout}");
      // print(session.stderr);
      session.stdout.listen((data) {
        if (kDebugMode) {
          print("std out : ${utf8.decode(data)}");
        }
      });
      session.stderr.listen((data) {
        if (kDebugMode) {
          print("std err : ${utf8.decode(data)}");
        }
      });
      // print('STDOUT:\n$stdout');

      // final stderr = await session.stderr.transform(utf8.decoder).join();
      // print('STDERR:\n$stderr');

      // ignore: avoid_print
      print('Command sent to $host:$port');
    } catch (e) {
      if (kDebugMode) {
        print('Failed to send command to $host:$port, $e');
      }
    }
    return this;
  }

  Future<void> changeToMars() async {
    try {
      String blankKml =
          '<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom"><Document></Document></kml>';
      await execCommand('echo "planet=mars" > /tmp/query.txt');
      await execCommand(
        'echo "$blankKml" > /var/www/html/kml/slave_$balloonScreen.kml',
      );
      marsSelected = true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to change to Mars, $e');
      }
    }
  }

  Future<void> sendLogos() async {
    if (kDebugMode) {
      print('Sending logos to Liquid Galaxy...');
    }
    String logo = await rootBundle.loadString('assets/kml/logos.kml');
    await execCommand("echo '$logo' > /var/www/html/kml/slave_$logoScreen.kml");
  }

  Future<void> _ensureSftp() async {
    if (_sftp != null) return;
    if (_connecting) {
      while (_connecting) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }
    _connecting = true;
    try {
      final socket = await SSHSocket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );
      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
        identities: const [],
      );
      _sftp = await _client!.sftp();
    } catch (e) {
      if (kDebugMode) {
        print('SFTP init failed: $e');
      }
      try {
        _client?.close();
      } catch (_) {}
      _client = null;
      _sftp = null;
    } finally {
      _connecting = false;
    }
  }

  Future<void> disposePersistent() async {
    try {
      _sftp?.close();
      _client?.close();
    } catch (_) {}
    _sftp = null;
    _client = null;
  }

  Future<LgService> sendFile(String remoteFilepath, Uint8List content) async {
    _fileQueue = _fileQueue.then((_) async {
      final hash = md5.convert(content).toString();
      final lastHash = _lastFileHash[remoteFilepath];
      if (lastHash == hash) {
        if (kDebugMode) {
          print('sendFile skipped (unchanged): $remoteFilepath');
        }
        return;
      }

      await _ensureSftp();
      if (_sftp == null) {
        if (kDebugMode) {
          print('Falling back (no persistent SFTP) for $remoteFilepath');
        }
        await _legacySendFile(remoteFilepath, content);
        _lastFileHash[remoteFilepath] = hash;
        return;
      }

      try {
        final file = await _sftp!.open(
          remoteFilepath,
          mode:
              SftpFileOpenMode.create |
              SftpFileOpenMode.truncate |
              SftpFileOpenMode.write,
        );

        const int chunkSize = 32 * 1024;
        int offset = 0;
        while (offset < content.length) {
          final end = (offset + chunkSize).clamp(0, content.length);
          final slice = content.sublist(offset, end);
          await file.write(
            Stream<Uint8List>.fromIterable([slice]),
            offset: offset,
          );
          offset = end;
        }
        await file.close();
        _lastFileHash[remoteFilepath] = hash;
        if (kDebugMode) {
          print('sendFile done (reused SFTP): $remoteFilepath');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Persistent send failed ($remoteFilepath): $e');
        }
        try {
          await disposePersistent();
        } catch (_) {}
        await _legacySendFile(remoteFilepath, content);
        _lastFileHash[remoteFilepath] = hash;
      }
    });
    await _fileQueue;
    return this;
  }

  Future<void> _legacySendFile(String remoteFilepath, Uint8List content) async {
    try {
      final socket = await SSHSocket.connect(host, port);
      final client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );
      final sftp = await client.sftp();
      final file = await sftp.open(
        remoteFilepath,
        mode:
            SftpFileOpenMode.truncate |
            SftpFileOpenMode.create |
            SftpFileOpenMode.write,
      );
      await file.write(Stream.fromIterable([content]), offset: 0);
      await file.close();
      sftp.close();
      client.close();
      if (kDebugMode) {
        print('Legacy sendFile done: $remoteFilepath');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Legacy sendFile failed: $e');
      }
    }
  }

  Future<SSHClient> getClient(host, port, username, password) async {
    final socket = await SSHSocket.connect(host, port);
    return SSHClient(
      socket,
      username: username,
      onPasswordRequest: () => password,
    );
  }

  Future<void> setRefresh() async {
    final pw = password;

    const search = '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href>';
    const replace =
        '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href><refreshMode>onInterval<\\/refreshMode><refreshInterval>2<\\/refreshInterval>';
    final command =
        'echo $pw | sudo -S sed -i "s/$search/$replace/" ~/earth/kml/slave/myplaces.kml';

    final clear =
        'echo $pw | sudo -S sed -i "s/$replace/$search/" ~/earth/kml/slave/myplaces.kml';

    for (var i = 2; i <= rigs; i++) {
      final clearCmd = clear.replaceAll('{{slave}}', i.toString());
      final cmd = command.replaceAll('{{slave}}', i.toString());
      String query = 'sshpass -p $pw ssh -t lg$i \'{{cmd}}\'';

      try {
        await execCommand(query.replaceAll('{{cmd}}', clearCmd));
        await execCommand(query.replaceAll('{{cmd}}', cmd));
      } catch (e) {
        // ignore: avoid_print
        print(e);
      }
    }

    await reboot();
  }

  Future<void> resetRefresh() async {
    final pw = password;

    const search =
        '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href><refreshMode>onInterval<\\/refreshMode><refreshInterval>2<\\/refreshInterval>';
    const replace = '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href>';

    final clear =
        'echo $pw | sudo -S sed -i "s/$search/$replace/" ~/earth/kml/slave/myplaces.kml';

    for (var i = 2; i <= rigs; i++) {
      final cmd = clear.replaceAll('{{slave}}', i.toString());
      String query = 'sshpass -p $pw ssh -t lg$i \'$cmd\'';

      try {
        await execCommand(query);
      } catch (e) {
        // ignore: avoid_print
        print(e);
      }
    }

    await reboot();
  }

  Future<void> reboot() async {
    final pw = password;

    for (var i = rigs; i >= 1; i--) {
      try {
        await execCommand(
          'sshpass -p $pw ssh -t lg$i "echo $pw | sudo -S reboot"',
        );
        // await Future.delayed(Duration(seconds: 25));

        // await checkConnection();
      } catch (e) {
        // ignore: avoid_print
        print(e);
      }
    }
  }

  Future<void> relaunch() async {
    final pw = password;

    for (var i = rigs; i >= 1; i--) {
      try {
        final relaunchCommand = """
RELAUNCH_CMD="\\
if [ -f /etc/init/lxdm.conf ]; then
  export SERVICE=lxdm
elif [ -f /etc/init/lightdm.conf ]; then
  export SERVICE=lightdm
else
  exit 1
fi
if  [[ \\\$(service \\\$SERVICE status) =~ 'stop' ]]; then
  echo $pw | sudo -S service \\\${SERVICE} start
else
  echo $pw | sudo -S service \\\${SERVICE} restart
fi
" && sshpass -p $pw ssh -x -t lg@lg$i "\$RELAUNCH_CMD\"""";
        // await execCommand(
        //   '"/home/$user/bin/lg-relaunch" > /home/$user/log.txt',
        // );
        await execCommand(relaunchCommand);
        // await checkConnection();
      } catch (e) {
        // ignore: avoid_print
        print(e);
      }
    }
    await Future.delayed(Duration(seconds: 15));
    await changeToMars();
  }

  /// Shuts down the Liquid Galaxy system.
  Future<void> shutdown() async {
    final pw = password;

    for (var i = rigs; i >= 1; i--) {
      try {
        await execCommand(
          'sshpass -p $pw ssh -t lg$i "echo $pw | sudo -S poweroff"',
        );
      } catch (e) {
        // ignore: avoid_print
        print(e);
      }
    }
  }

  Future<void> clearKml({bool keepLogos = true}) async {
    String query =
        'echo "exittour=true" > /tmp/query.txt && > /var/www/html/kmls.txt';

    for (var i = 2; i <= rigs; i++) {
      String blankKml =
          '<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom"><Document></Document></kml>';
      if (i != logoScreen) {
        query += " && echo '$blankKml' > /var/www/html/kml/slave_$i.kml";
      }
    }

    await execCommand(query);
  }

  Future<void> loadSavedData(Future<SharedPreferences> prefs) async {
    final SharedPreferences preferences = await prefs;
    host = preferences.getString('host') ?? host;
    port = preferences.getInt('port') ?? port;
    username = preferences.getString('username') ?? username;
    password = preferences.getString('password') ?? password;
    rigs = preferences.getInt('rigs') ?? rigs;
  }
}
