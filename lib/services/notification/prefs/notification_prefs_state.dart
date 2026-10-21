class NotificationPrefsState {
  const NotificationPrefsState({
    this.alert80Enabled = true,
    this.alert100Enabled = true,
    this.isLoading = true,
    this.hasLoaded = false,
    this.isSaving = false,
    this.errorMessage,
  });

  final bool alert80Enabled;
  final bool alert100Enabled;
  final bool isLoading;
  final bool hasLoaded;
  final bool isSaving;
  final String? errorMessage;

  static const Object _unset = Object();

  NotificationPrefsState copyWith({
    bool? alert80Enabled,
    bool? alert100Enabled,
    bool? isLoading,
    bool? hasLoaded,
    bool? isSaving,
    Object? errorMessage = _unset,
  }) {
    return NotificationPrefsState(
      alert80Enabled: alert80Enabled ?? this.alert80Enabled,
      alert100Enabled: alert100Enabled ?? this.alert100Enabled,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
