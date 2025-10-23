class MonetizationState {
  const MonetizationState({
    required this.isTrialActive,
    required this.trialEndsAt,
    required this.isSubscribed,
    required this.sessionsRemaining,
  });

  const MonetizationState.initial()
      : isTrialActive = false,
        trialEndsAt = null,
        isSubscribed = false,
        sessionsRemaining = defaultSessions;

  static const int defaultSessions = 3;

  final bool isTrialActive;
  final DateTime? trialEndsAt;
  final bool isSubscribed;
  final int sessionsRemaining;

  bool get trialExpired {
    if (!isTrialActive || trialEndsAt == null) {
      return true;
    }
    return DateTime.now().isAfter(trialEndsAt!);
  }

  bool get canAccessPremium => isSubscribed || (isTrialActive && !trialExpired);

  MonetizationState copyWith({
    bool? isTrialActive,
    DateTime? trialEndsAt,
    bool? isSubscribed,
    int? sessionsRemaining,
  }) {
    return MonetizationState(
      isTrialActive: isTrialActive ?? this.isTrialActive,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      sessionsRemaining: sessionsRemaining ?? this.sessionsRemaining,
    );
  }

  MonetizationState resetSessions() {
    return copyWith(sessionsRemaining: defaultSessions);
  }
}
