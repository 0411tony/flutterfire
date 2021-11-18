import 'package:flutter_test/flutter_test.dart';

import 'firebase_database_e2e.dart';

void runDatabaseTests() {
  group('FirebaseDatabase.ref()', () {
    setUp(() async {
      await database.ref('flutterfire').set(0);
    });

    test('returns a correct reference', () async {
      final snapshot = await database.ref('flutterfire').get();
      expect(snapshot.key, 'flutterfire');
      expect(snapshot.value, 0);
    });

    test(
      'returns a reference to the root of the database if no path specified',
      () async {
        final ref = database.ref().child('flutterfire');
        final snapshot = await ref.get();
        expect(snapshot.key, 'flutterfire');
        expect(snapshot.value, 0);
      },
    );
  });

  group('FirebaseDatabase.refFromURL()', () {
    test('correctly returns a ref for database root', () async {
      final ref = database
          .refFromURL('https://react-native-firebase-testing.firebaseio.com');
      expect(ref.key, null);

      final refWithTrailingSlash = database
          .refFromURL('https://react-native-firebase-testing.firebaseio.com/');
      expect(refWithTrailingSlash.key, null);
    });

    test('correctly returns a ref for any database path', () async {
      final ref = database.refFromURL(
        'https://react-native-firebase-testing.firebaseio.com/foo',
      );
      expect(ref.key, 'foo');

      final refWithNestedPath = database.refFromURL(
        'https://react-native-firebase-testing.firebaseio.com/foo/bar',
      );
      expect(refWithNestedPath.parent?.key, 'foo');
      expect(refWithNestedPath.key, 'bar');
    });

    test('throws [ArgumentError] if not a valid https:// url', () async {
      expect(() => database.refFromURL('foo'), throwsArgumentError);
    });

    test('throws [ArgumentError] if database url does not match instance url',
        () async {
      expect(
        () => database.refFromURL('https://some-other-database.firebaseio.com'),
        throwsArgumentError,
      );
    });
  });
}
