import 'package:martian_climate_dashboard/entities/balloon_entity.dart';
import 'package:martian_climate_dashboard/enums/colomap.dart';
import 'package:martian_climate_dashboard/services/lg_service.dart';

class BalloonService {
  final BalloonEntity balloonEntity;

  BalloonService(this.balloonEntity);

  Future<void> showVisBalloon(
    LgService lgService,
    String content,
    ColorMap colorMap,
  ) async {
    String xmlContent = balloonEntity.generateVisualizationBalloon(
      colorMap,
      content,
    );
    await lgService.execCommand(
      "echo '$xmlContent' > /var/www/html/kml/slave_${lgService.balloonScreen}.kml",
    );
  }

  static Future<void> showLocationBalloon(
    LgService lgService,
    String content,
    String title,
    List<dynamic> coordinates,
  ) async {
    String xmlContent = BalloonEntity.generateLocationBalloon(
      content,
      title,
      coordinates,
    );
    await lgService.execCommand(
      "echo '$xmlContent' > /var/www/html/kml/slave_${lgService.balloonScreen}.kml",
    );
  }
}
