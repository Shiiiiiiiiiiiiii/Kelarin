import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/auth_service.dart';

// User model
class AppUser {
  final String id;
  final String email;
  final String name;

  const AppUser({required this.id, required this.email, required this.name});
}

// Provider untuk mendapatkan data user saat ini yang sudah dimapping
final userProvider = Provider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.maybeWhen(
    data: (user) {
      if (user == null) return null;
      return AppUser(
        id: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? user.email?.split('@')[0] ?? 'User',
      );
    },
    orElse: () => null,
  );
});
