import 'package:arrivo/services/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemorySecretStore implements SecretStore {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);
}

void main() {
  late LocalAuthRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = LocalAuthRepository(prefs, MemorySecretStore());
  });

  test('sign up creates an account and signs the user in', () async {
    final user = await repo.signUp(name: 'Maria Santos', email: 'Maria@Mail.com', password: 'secret1');
    expect(user.email, 'maria@mail.com');
    expect(user.initials, 'MS');
    expect((await repo.currentUser())?.name, 'Maria Santos');
  });

  test('sign up rejects a duplicate email', () async {
    await repo.signUp(name: 'A', email: 'a@mail.com', password: 'secret1');
    expect(
      () => repo.signUp(name: 'B', email: 'a@mail.com', password: 'secret2'),
      throwsA(isA<AuthException>().having((e) => e.message, 'message', 'Account already exists')),
    );
  });

  test('sign up validates email and password length', () async {
    expect(() => repo.signUp(name: 'A', email: 'nope', password: 'secret1'), throwsA(isA<AuthException>()));
    expect(() => repo.signUp(name: 'A', email: 'a@mail.com', password: '123'), throwsA(isA<AuthException>()));
  });

  test('log in works with the right password and fails with a wrong one', () async {
    await repo.signUp(name: 'A', email: 'a@mail.com', password: 'secret1');
    await repo.logOut();
    expect(await repo.currentUser(), isNull);

    expect(
      () => repo.logIn(email: 'a@mail.com', password: 'wrong'),
      throwsA(isA<AuthException>().having((e) => e.message, 'message', 'Wrong email or password')),
    );
    final user = await repo.logIn(email: ' A@mail.com ', password: 'secret1');
    expect(user.name, 'A');
  });

  test('log out clears the session', () async {
    await repo.signUp(name: 'A', email: 'a@mail.com', password: 'secret1');
    await repo.logOut();
    expect(await repo.currentUser(), isNull);
  });
}
