// The time-range options shown as chips on the node dashboard, used to
// filter which readings get charted/exported.
enum Timeframe { h2, h4, h8, h24, all }

extension TimeframeX on Timeframe {
  // Short text shown on the UI's ChoiceChip for each option.
  String get label {
    switch (this) {
      case Timeframe.h2:
        return '2h';
      case Timeframe.h4:
        return '4h';
      case Timeframe.h8:
        return '8h';
      case Timeframe.h24:
        return '24h';
      case Timeframe.all:
        return 'All';
    }
  }

  // Actual window length used to filter readings (see filterByTimeframe
  // in services/stats.dart). Null means "no filtering" (show everything).
  Duration? get duration {
    switch (this) {
      case Timeframe.h2:
        return const Duration(hours: 2);
      case Timeframe.h4:
        return const Duration(hours: 4);
      case Timeframe.h8:
        return const Duration(hours: 8);
      case Timeframe.h24:
        return const Duration(hours: 24);
      case Timeframe.all:
        return null;
    }
  }
}
