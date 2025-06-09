/// Represents the parameters for a Mars Climate Database API request.
///
/// Each field corresponds to a query parameter in the API.
/// See:
/// https://www-mars.lmd.jussieu.fr/mcd_python/cgi-bin/mcdcgi.py
class ApiEntity {
  /// The main variable to request (e.g., temperature).
  String? variable;

  /// Whether to return HTML-formatted date keys (1 = yes).
  int datekeyhtml = 1;

  /// Areocentric solar longitude (degrees).
  double? ls = 93.3;

  /// Local time (hours).
  double? localtime = 0;

  /// Earth year.
  int? year;

  /// Earth month.
  int? month;

  /// Earth day.
  int? day;

  /// Hour of the day.
  int? hours;

  /// Minute of the hour.
  int? minutes;

  /// Second of the minute.
  int? seconds;

  /// Julian date.
  double? julian;

  /// Martian year.
  int? martianyear;

  /// Martian sol (day).
  int? sol;

  /// Latitude (can be a value or "all").
  String? latitude;

  /// Longitude (can be a value or "all").
  String? longitude;

  /// Altitude (km).
  double? altitude;

  /// Vertical coordinate key.
  int? zkey;

  /// Spacecraft name or "none".
  String? spacecraft = "none";

  /// Whether to use fixed local time ("on"/"off").
  String? isfixedlt = "off";

  /// Dust scenario.
  String? dust;

  /// Hour key.
  int? hrkey;

  /// Averaging mode ("on"/"off").
  String? averaging;

  /// Dots per inch for images.
  int? dpi;

  /// Whether to use logarithmic scale ("on"/"off").
  String? islog;

  /// Color map name.
  String? colorm;

  /// Minimum value for color scale.
  String? minval;

  /// Maximum value for color scale.
  String? maxval;

  /// Projection type.
  String? proj;

  /// Altitude for a point (km).
  double? palt;

  /// Longitude for a point.
  double? plon;

  /// Latitude for a point.
  double? plat;

  ApiEntity({
    this.variable,
    this.datekeyhtml = 1,
    this.ls = 93.3,
    this.localtime = 0,
    this.year,
    this.month,
    this.day,
    this.hours,
    this.minutes,
    this.seconds,
    this.julian,
    this.martianyear,
    this.sol,
    this.latitude = 'all',
    this.longitude = 'all',
    this.altitude,
    this.zkey,
    this.spacecraft = 'none',
    this.isfixedlt = 'off',
    this.dust = '1',
    this.hrkey = 1,
    this.averaging = 'off',
    this.dpi = 80,
    this.islog = 'off',
    this.colorm = 'jet',
    this.minval,
    this.maxval,
    this.proj = 'cyl',
    this.palt,
    this.plon,
    this.plat,
  });

  Uri uri() {
    final params = {
      'var1': variable ?? 't',
      'var2': 'none',
      'var3': 'none',
      'var4': 'none',
      'datekeyhtml': datekeyhtml.toString(),
      'ls': ls?.toString() ?? '',
      'localtime': localtime?.toString() ?? '',
      'year': year?.toString() ?? '',
      'month': month?.toString() ?? '',
      'day': day?.toString() ?? '',
      'hours': hours?.toString() ?? '',
      'minutes': minutes?.toString() ?? '',
      'seconds': seconds?.toString() ?? '',
      'julian': julian?.toString() ?? '',
      'martianyear': martianyear?.toString() ?? '',
      'sol': sol?.toString() ?? '',
      'latitude': latitude ?? 'all',
      'longitude': longitude ?? 'all',
      'altitude': altitude?.toString() ?? '',
      'zkey': zkey?.toString() ?? '',
      'spacecraft': spacecraft,
      'isfixedlt': isfixedlt,
      'dust': dust,
      'hrkey': hrkey?.toString() ?? '',
      'averaging': averaging,
      'dpi': dpi?.toString() ?? '',
      'islog': islog,
      'colorm': colorm,
      'minval': minval,
      'maxval': maxval,
      'proj': proj,
      'palt': palt?.toString() ?? '',
      'plon': plon?.toString() ?? '',
      'plat': plat?.toString() ?? '',
    };

    return Uri.https(
      'www-mars.lmd.jussieu.fr',
      '/mcd_python/cgi-bin/mcdcgi.py',
      params,
    );
  }
}

// https://www-mars.lmd.jussieu.fr/mcd_python/cgi-bin/mcdcgi.py?ls=93.3&localtime=0.&year=2025&month=6&day=6&hours=19&minutes=28&seconds=21&julian=2460833.3113541664&martianyear=38&sol=201&latitude=all&longitude=all&altitude=10.&zkey=3&spacecraft=none&isfixedlt=off&dust=1&hrkey=1&averaging=off&dpi=80&islog=off&colorm=jet&minval=&maxval=&proj=cyl&palt=&plon=&plat=&trans=&iswind=off&latpoint=&lonpoint=
// https://www-mars.lmd.jussieu.fr/mcd_python/cgi-bin/mcdcgi.py?var1=t&var2=none&var3=none&var4=none&datekeyhtml=1&ls=93.3&localtime=0.&year=2025&month=6&day=6&hours=19&minutes=28&seconds=21&julian=2460833.3113541664&martianyear=38&sol=201&latitude=all&longitude=all&altitude=10.&zkey=3&spacecraft=none&isfixedlt=off&dust=1&hrkey=1&averaging=off&dpi=80&islog=off&colorm=jet&minval=&maxval=&proj=cyl&palt=&plon=&plat=&trans=&iswind=off&latpoint=&lonpoint=
