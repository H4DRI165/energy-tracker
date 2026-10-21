import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/services/notification/service/provider/notification_service_provider.dart';
import 'package:energy_tracker/ui/components/logging/app_logger.dart';
import 'package:energy_tracker/ui/components/logging/notifier/loggable_notifier.dart';
import 'package:energy_tracker/ui/features/ft_onboarding/notifier/onboarding_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<OnboardingNotifier, OnboardingPageState>
onboardingProvider =
    NotifierProvider.autoDispose<OnboardingNotifier, OnboardingPageState>(
      OnboardingNotifier.new,
    );

class OnboardingNotifier extends Notifier<OnboardingPageState>
    with LoggableNotifier<OnboardingPageState> {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  String get screenName => 'OnboardingPage';

  @override
  OnboardingPageState build() => const OnboardingPageState();

  void setBudget(double budget) {
    state = state.copyWith(monthlyBudget: budget);
  }

  void nextFromBudget() {
    state = state.copyWith(currentStep: 1);
  }

  void goBack() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  Future<bool> completeOnboarding() async {
    final authUser = FirebaseAuth.instance.currentUser;
    final uid = authUser?.uid;

    if (uid == null) {
      state = state.copyWith(
        errorMessage: 'User session expired. Please sign in again.',
      );

      return false;
    }

    final signedInUser = authUser!;
    // Read this before any async gap. Completing onboarding changes the auth
    // route and can dispose this auto-dispose provider immediately.
    final notificationService = ref.read(notificationServiceProvider);

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      final userRef = _firestore.collection('users').doc(uid);
      final existing = await userRef.get();
      final existingData = existing.data() ?? const <String, dynamic>{};

      final existingName = existingData['fullName'];
      final existingEmail = existingData['email'];
      final existingTnbAccount = existingData['tnbAccountNo'];

      final fullName = existingName is String && existingName.trim().isNotEmpty
          ? existingName
          : signedInUser.displayName ??
                signedInUser.email?.split('@').first ??
                'User';
      final email = existingEmail is String && existingEmail.isNotEmpty
          ? existingEmail
          : signedInUser.email ?? '';
      final tnbAccountNo = existingTnbAccount is String
          ? existingTnbAccount
          : '';

      // Google sign-in does not create a Firestore profile. A merge write with
      // the identity fields works for both create and update, so onboarding
      // can bootstrap either type of account.
      await userRef.set(
        {
          'uid': uid,
          'fullName': fullName,
          'email': email,
          'tnbAccountNo': tnbAccountNo,
          'monthlyBudget': state.monthlyBudget,
          'onboardingCompleted': true,
          if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // The profile now exists, so the FCM token can be attached safely.
      await notificationService.syncToken();
      return true;
    } on FirebaseException catch (e, st) {
      logError(
        'Failed to complete onboarding (Firebase)',
        e,
        st,
        context: {
          'monthly_budget': state.monthlyBudget,
        },
      );
      if (ref.mounted) {
        state = state.copyWith(errorMessage: mapFirebaseError(e.code));
      }
      return false;
    } on Exception catch (e, st) {
      logError(
        'Onboarding unexpected exception',
        e,
        st,
        context: {
          'monthly_budget': state.monthlyBudget,
        },
      );
      if (ref.mounted) {
        state = state.copyWith(
          errorMessage: 'Failed to save settings. Please try again.',
        );
      }
      return false;
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }
}
