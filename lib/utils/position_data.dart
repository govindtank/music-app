class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  const PositionData(
    this.position,
    this.bufferedPosition,
    this.duration,
  );

  PositionData copyWith({
    Duration? position,
    Duration? bufferedPosition,
    Duration? duration,
  }) {
    return PositionData(
      position ?? this.position,
      bufferedPosition ?? this.bufferedPosition,
      duration ?? this.duration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PositionData &&
        other.position == position &&
        other.bufferedPosition == bufferedPosition &&
        other.duration == duration;
  }

  @override
  int get hashCode {
    return position.hashCode ^
        bufferedPosition.hashCode ^
        duration.hashCode;
  }

  @override
  String toString() {
    return 'PositionData(position: $position, bufferedPosition: $bufferedPosition, duration: $duration)';
  }
}
