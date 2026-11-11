// Holidays per O. Reg. 722/94, r.2 - Ontario POA Appeals
// Source: https://www.ontario.ca/laws/regulation/940722
// NOT federal CAS list - CAS is for Federal Court, not POA.
// Rule-based: computes for any year, applies observed rules from r.2(4).

class CanadaHolidays {
  static String currentProvince = 'Ontario';

  // Easter Sunday - Anonymous Gregorian algorithm
  static DateTime _easterSunday(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }

  static DateTime _mondayBeforeMay25(int year) {
    // Victoria Day: Monday before May 25
    var d = DateTime(year, 5, 25);
    while (d.weekday != DateTime.monday) d = d.subtract(const Duration(days: 1));
    return d;
  }
  static DateTime _firstMonday(int year, int month) {
    var d = DateTime(year, month, 1);
    while (d.weekday != DateTime.monday) d = d.add(const Duration(days: 1));
    return d;
  }
  static DateTime _secondMonday(int year, int month) {
    return _firstMonday(year, month).add(const Duration(days: 7));
  }

  // Returns map of Date -> Holiday Name for a year, per O. Reg. 722/94 r.2(3)+(4)
  static Map<DateTime, String> holidaysForYear(int year, {String? province}) {
    final prov = province ?? currentProvince;
    final easter = _easterSunday(year);
    final map = <DateTime, String>{};
    void add(DateTime d, String name) => map[DateTime(d.year, d.month, d.day)] = name;

    add(DateTime(year, 1, 1), "New Year's Day");
    add(easter.subtract(const Duration(days: 2)), 'Good Friday');
    add(easter.add(const Duration(days: 1)), 'Easter Monday');
    add(_mondayBeforeMay25(year), prov == 'Quebec' ? "National Patriots' Day" : 'Victoria Day');
    add(DateTime(year, 7, 1), 'Canada Day');
    add(_firstMonday(year, 8), prov == 'Quebec' ? 'Civic Holiday (not observed in QC)' : 'Civic Holiday');
    add(_firstMonday(year, 9), 'Labour Day');
    add(_secondMonday(year, 10), 'Thanksgiving Day');
    add(DateTime(year, 11, 11), 'Remembrance Day');
    add(DateTime(year, 12, 25), 'Christmas Day');
    add(DateTime(year, 12, 26), 'Boxing Day');

    // Quebec extra
    if (prov == 'Quebec') {
      add(DateTime(year, 6, 24), 'St-Jean-Baptiste Day');
      add(DateTime(year, 1, 2), 'Day after New Year (Quebec)');
    }
    // Federal CAS extra - Truth and Reconciliation (federal courts, info only for Ontario POA - not a POA holiday per O. Reg, but shown as note)
    // We do NOT block on it for POA, but we note it.

    // Observed rules - O. Reg. 722/94 r.2(4)
    // (a) New Year, Canada Day, Remembrance on Sat/Sun -> following Monday
    for (final base in [DateTime(year, 1, 1), DateTime(year, 7, 1), DateTime(year, 11, 11)]) {
      if (base.weekday == DateTime.saturday || base.weekday == DateTime.sunday) {
        var mon = base;
        while (mon.weekday != DateTime.monday) mon = mon.add(const Duration(days: 1));
        final orig = map[DateTime(base.year, base.month, base.day)];
        if (orig != null) add(mon, '$orig (observed)');
      }
    }
    // (b) Christmas Sat/Sun -> following Mon + Tue
    final xmas = DateTime(year, 12, 25);
    if (xmas.weekday == DateTime.saturday || xmas.weekday == DateTime.sunday) {
      var mon = xmas;
      while (mon.weekday != DateTime.monday) mon = mon.add(const Duration(days: 1));
      add(mon, 'Christmas Day (observed)');
      add(mon.add(const Duration(days: 1)), 'Boxing Day (observed)');
    }
    // (c) Christmas Fri -> following Monday
    if (xmas.weekday == DateTime.friday) {
      add(xmas.add(const Duration(days: 3)), 'Boxing Day (observed)');
    }
    return map;
  }

  static String? holidayName(DateTime dt, {String? province}) {
    final map = holidaysForYear(dt.year, province: province);
    return map[DateTime(dt.year, dt.month, dt.day)];
  }

  static bool isCourtClosed(DateTime dt, {String? province}) {
    if (dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday) return true;
    return holidayName(dt, province: province) != null;
  }

  static DateTime nextBusinessDay(DateTime dt, {String? province}) {
    var d = DateTime(dt.year, dt.month, dt.day).add(const Duration(days: 1));
    while (isCourtClosed(d, province: province)) d = d.add(const Duration(days: 1));
    return d;
  }
}
