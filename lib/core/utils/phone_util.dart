/// Indian mobile numbers: ten digits starting 6–9, with an optional +91 or a
/// leading 0. Returns the bare ten digits, or null when it isn't one.
String? cleanIndianMobile(String raw) {
  var d = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.length == 12 && d.startsWith('91')) d = d.substring(2);
  if (d.length == 11 && d.startsWith('0')) d = d.substring(1);
  return RegExp(r'^[6-9]\d{9}$').hasMatch(d) ? d : null;
}
