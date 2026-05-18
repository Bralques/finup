import 'package:intl/intl.dart';

extension DateExtension on DateTime {
  String toMonthYear({String locale = 'pt_BR'}) {
    return DateFormat('MMMM yyyy', locale).format(this);
  }

  String toShortDate({String locale = 'pt_BR'}) {
    return DateFormat('dd/MM/yyyy', locale).format(this);
  }

  String toLongDate({String locale = 'pt_BR'}) {
    return DateFormat("dd 'de' MMMM 'de' yyyy", locale).format(this);
  }

  String toDayMonth({String locale = 'pt_BR'}) {
    return DateFormat('dd/MM', locale).format(this);
  }

  String toWeekDay({String locale = 'pt_BR'}) {
    return DateFormat('EEEE', locale).format(this);
  }

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  bool isSameMonth(DateTime other) {
    return year == other.year && month == other.month;
  }

  DateTime get firstDayOfMonth => DateTime(year, month, 1);
  DateTime get lastDayOfMonth => DateTime(year, month + 1, 0);

  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);

  int get daysInMonth => DateTime(year, month + 1, 0).day;

  bool get isToday {
    final now = DateTime.now();
    return isSameDay(now);
  }

  bool get isThisMonth {
    final now = DateTime.now();
    return isSameMonth(now);
  }

  int daysUntil(DateTime other) {
    return other.difference(startOfDay).inDays;
  }
}

extension NullableDateExtension on DateTime? {
  String toShortDateOrEmpty({String empty = '--/--/----'}) {
    return this?.toShortDate() ?? empty;
  }
}
