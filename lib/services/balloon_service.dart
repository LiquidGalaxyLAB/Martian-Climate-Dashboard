import 'package:martian_climate_dashboard/entities/balloon_entity.dart';
import 'package:martian_climate_dashboard/services/lg_service.dart';

class BalloonService {
  final BalloonEntity balloonEntity;

  BalloonService(this.balloonEntity);

  Future<void> showBalloon(LgService lgService, String content) async {
    String xmlContent = balloonEntity.generateXml(content);
    await lgService.execCommand(
      "echo '$xmlContent' > /var/www/html/kml/slave_2.kml",
    );
  }
}
