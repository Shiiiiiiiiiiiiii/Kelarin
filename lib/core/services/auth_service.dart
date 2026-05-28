import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Layanan autentikasi yang mengelola seluruh operasi login dan logout pengguna.
///
/// Mendukung dua metode masuk:
/// - **Email & Password** menggunakan Firebase Auth.
/// - **Google Sign-In** menggunakan paket `google_sign_in`.
///
/// Gunakan [authServiceProvider] untuk mengakses instance-nya via Riverpod.
/// Gunakan [authStateProvider] untuk memantau perubahan status login secara real-time.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream yang memancarkan perubahan status pengguna, termasuk perubahan profil
  /// seperti `displayName`. Menggunakan `userChanges()` (bukan `authStateChanges`)
  /// agar perubahan profil seperti nama tampilan juga terpantau.
  Stream<User?> get authStateChanges => _auth.userChanges();

  /// Masuk menggunakan email dan password.
  ///
  /// Melempar exception Firebase jika kredensial salah atau email tidak ditemukan.
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  /// Membuat akun baru dengan email dan password.
  ///
  /// Melempar exception Firebase jika email sudah terdaftar atau password terlalu lemah.
  Future<UserCredential?> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  /// Masuk menggunakan akun Google.
  ///
  /// Mengembalikan `null` jika pengguna membatalkan dialog pemilihan akun Google.
  /// Proses: Google Sign-In → ambil token → buat credential Firebase → login.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User membatalkan login

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  /// Mengirim email tautan reset password ke alamat [email] yang diberikan.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  /// Memperbarui nama tampilan (display name) pengguna yang sedang login.
  ///
  /// Melempar exception jika tidak ada pengguna yang sedang login.
  /// Memanggil `user.reload()` setelah update agar perubahan langsung terpantau
  /// oleh [authStateChanges].
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');
    await user.updateDisplayName(name);
    await user.reload();
  }

  /// Keluar dari aplikasi, termasuk mencabut sesi Google Sign-In.
  ///
  /// Kedua operasi (`googleSignIn.signOut` dan `auth.signOut`) perlu dipanggil
  /// agar sesi Google tidak tersimpan dan akun pilihan muncul kembali saat login berikutnya.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Mendapatkan objek [User] Firebase yang sedang aktif, atau `null` jika belum login.
  User? get currentUser => _auth.currentUser;
}

/// Provider untuk mengakses instance [AuthService].
final authServiceProvider = Provider((ref) => AuthService());

/// Provider yang memantau status autentikasi pengguna secara real-time.
///
/// Memancarkan objek [User] saat pengguna login, atau `null` saat logout.
/// Digunakan oleh `AuthWrapper` untuk mengarahkan pengguna ke halaman yang tepat.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
