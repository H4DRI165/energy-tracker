class NotificationPrefsState {
  const NotificationPrefsState({
    this.alert80Enabled = true,
    this.alert100Enabled = true,
    this.isLoading = true,
  });

  final bool alert80Enabled;
  final bool alert100Enabled;
  final bool isLoading;

  NotificationPrefsState copyWith({
    bool? alert80Enabled,
    bool? alert100Enabled,
    bool? isLoading,
  }) {
    return NotificationPrefsState(
      alert80Enabled: alert80Enabled ?? this.alert80Enabled,
      alert100Enabled: alert100Enabled ?? this.alert100Enabled,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
