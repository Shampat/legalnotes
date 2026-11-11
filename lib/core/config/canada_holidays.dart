class CanadaHolidays {
  static const Map<String, String> federal2026 = {
    '2026-01-01': "New Year's Day",
    '2026-04-03': 'Good Friday',
    '2026-07-01': 'Canada Day',
    '2026-09-07': 'Labour Day',
    '2026-12-25': 'Christmas Day',
  };
  static const Map<String, String> federal2027 = {
    '2027-01-01': "New Year's Day",
    '2027-03-26': 'Good Friday',
    '2027-07-01': 'Canada Day',
    '2027-09-06': 'Labour Day',
    '2027-12-25': 'Christmas Day',
  };
  static const Map<String, Map<String, String>> provinceExtras = {
    'Ontario': {
      '2026-02-16': 'Family Day',
      '2026-05-18': 'Victoria Day',
      '2026-08-03': 'Civic Holiday',
      '2026-10-12': 'Thanksgiving',
      '2026-12-28': 'Boxing Day (observed)',
      '2027-02-15': 'Family Day',
      '2027-05-24': 'Victoria Day',
      '2027-08-02': 'Civic Holiday',
      '2027-10-11': 'Thanksgiving',
    },
    'Quebec': {
      '2026-01-02': 'Day after New Year (Quebec)',
      '2026-04-06': 'Easter Monday',
      '2026-05-18': "National Patriots' Day",
      '2026-06-24': 'St-Jean-Baptiste Day',
      '2026-10-12': 'Thanksgiving',
      '2027-01-02': 'Day after New Year (Quebec)',
      '2027-03-29': 'Easter Monday',
      '2027-05-24': "National Patriots' Day",
      '2027-06-24': 'St-Jean-Baptiste Day',
      '2027-10-11': 'Thanksgiving',
    },
    'British Columbia': {
      '2026-02-16': 'Family Day',
      '2026-05-18': 'Victoria Day',
      '2026-08-03': 'BC Day',
      '2026-09-30': 'Truth and Reconciliation Day',
      '2026-10-12': 'Thanksgiving',
      '2027-02-15': 'Family Day',
      '2027-05-24': 'Victoria Day',
      '2027-08-02': 'BC Day',
      '2027-09-30': 'Truth and Reconciliation Day',
      '2027-10-11': 'Thanksgiving',
    },
    'Alberta': {
      '2026-02-16': 'Family Day',
      '2026-05-18': 'Victoria Day',
      '2026-08-03': 'Heritage Day',
      '2026-10-12': 'Thanksgiving',
      '2026-11-11': 'Remembrance Day',
      '2027-02-15': 'Family Day',
      '2027-05-24': 'Victoria Day',
      '2027-08-02': 'Heritage Day',
      '2027-10-11': 'Thanksgiving',
      '2027-11-11': 'Remembrance Day',
    },
    'Other': {
      '2026-05-18': 'Victoria Day',
      '2026-10-12': 'Thanksgiving',
      '2027-05-24': 'Victoria Day',
      '2027-10-11': 'Thanksgiving',
    },
  };
  static String currentProvince = 'Ontario';
  static String? holidayName(DateTime dt, {String? province}) {
    final prov = province ?? currentProvince;
    final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    if (dt.year == 2026 && federal2026.containsKey(key)) return federal2026[key];
    if (dt.year == 2027 && federal2027.containsKey(key)) return federal2027[key];
    final extras = provinceExtras[prov] ?? provinceExtras['Other']!;
    return extras[key];
  }
  static bool isCourtClosed(DateTime dt, {String? province}) {
    return holidayName(dt, province: province) != null;
  }
  static DateTime nextBusinessDay(DateTime dt, {String? province}) {
    var d = DateTime(dt.year, dt.month, dt.day).add(const Duration(days: 1));
    while (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday || isCourtClosed(d, province: province)) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }
}
