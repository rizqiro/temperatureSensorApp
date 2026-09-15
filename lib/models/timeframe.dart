enum Timeframe { h2, h4, h8, h24, all }

extension TimeframeX on Timeframe {
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
