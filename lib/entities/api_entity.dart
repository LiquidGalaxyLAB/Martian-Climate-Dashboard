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
}

// https://www-mars.lmd.jussieu.fr/mcd_python/cgi-bin/mcdcgi.py?ls=93.3&localtime=0.&year=2025&month=6&day=6&hours=19&minutes=28&seconds=21&julian=2460833.3113541664&martianyear=38&sol=201&latitude=all&longitude=all&altitude=10.&zkey=3&spacecraft=none&isfixedlt=off&dust=1&hrkey=1&averaging=off&dpi=80&islog=off&colorm=jet&minval=&maxval=&proj=cyl&palt=&plon=&plat=&trans=&iswind=off&latpoint=&lonpoint=
// https://www-mars.lmd.jussieu.fr/mcd_python/cgi-bin/mcdcgi.py?var1=t&var2=none&var3=none&var4=none&datekeyhtml=1&ls=93.3&localtime=0.&year=2025&month=6&day=6&hours=19&minutes=28&seconds=21&julian=2460833.3113541664&martianyear=38&sol=201&latitude=all&longitude=all&altitude=10.&zkey=3&spacecraft=none&isfixedlt=off&dust=1&hrkey=1&averaging=off&dpi=80&islog=off&colorm=jet&minval=&maxval=&proj=cyl&palt=&plon=&plat=&trans=&iswind=off&latpoint=&lonpoint=
