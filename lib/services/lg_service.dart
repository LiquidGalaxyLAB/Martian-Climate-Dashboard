import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';

class LgService {
  String host = "192.168.121.3";
  int port = 22;
  String username = "lg";
  String password = "lg";
  int rigs = 3;

  Future<bool> checkConnection() async {
    try {
      print('Connecting to $host:$port...');
      final socket = await SSHSocket.connect(
        host,
        port,
        timeout: Duration(seconds: 5),
      );
      SSHClient(socket, username: username, onPasswordRequest: () => password);
      print('Connected to $host:$port');
      return true;
    } catch (e) {
      print('Failed to connect to $host:$port, $e');
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
      await client.execute(command);
      // ignore: avoid_print
      print('Command sent to $host:$port');
    } catch (e) {
      print('Failed to send command to $host:$port, $e');
    }
    return this;
  }

  Future<LgService> sendFile(String remoteFilepath, Uint8List content) async {
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

      final fileStream = Stream.fromIterable([content]);
      int offset = 0;

      await for (final chunk in fileStream) {
        await file.write(Stream.fromIterable([chunk]), offset: offset);
        offset += chunk.length;
      }
      print('Done sending file');
    } catch (e) {
      print('Failed to send file to $host:$port, $e');
    }
    return this;
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

  /// Reboots the Liquid Galaxy system.
  Future<void> reboot() async {
    final pw = password;

    for (var i = rigs; i >= 1; i--) {
      try {
        await execCommand(
          'sshpass -p $pw ssh -t lg$i "echo $pw | sudo -S reboot"',
        );
      } catch (e) {
        // ignore: avoid_print
        print(e);
      }
    }
  }

  /// Relaunches the Liquid Galaxy system.
  Future<void> relaunch() async {
    final pw = password;
    final user = username;

    for (var i = rigs; i >= 1; i--) {
      try {
        final relaunchCommand = """RELAUNCH_CMD="\\
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
        await execCommand(
          '"/home/$user/bin/lg-relaunch" > /home/$user/log.txt',
        );
        await execCommand(relaunchCommand);
      } catch (e) {
        // ignore: avoid_print
        print(e);
      }
    }
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
      String blankKml = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
  <Document>
  </Document>
</kml>
''';
      query += " && echo '$blankKml' > /var/www/html/kml/slave_$i.kml";
    }

    await execCommand(query);
  }
}
