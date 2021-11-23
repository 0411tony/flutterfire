// Copyright 2021, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_performance_platform_interface/firebase_performance_platform_interface.dart';
import 'package:firebase_performance_platform_interface/src/method_channel/method_channel_firebase_performance.dart';
import 'package:firebase_performance_platform_interface/src/method_channel/method_channel_trace.dart';
import 'package:firebase_performance_platform_interface/src/method_channel/method_channel_http_metric.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mock.dart';

void main() {
  setupFirebasePerformanceMocks();
  late TestMethodChannelFirebasePerformance mockPerformance;
  late FirebasePerformancePlatform performance;
  late FirebaseApp app;
  final List<MethodCall> log = <MethodCall>[];

  // mock props
  bool mockPlatformExceptionThrown = false;
  bool mockExceptionThrown = false;

  group('$MethodChannelFirebasePerformance', () {
    setUpAll(() async {
      app = await Firebase.initializeApp();

      handleMethodCall((call) async {
        log.add(call);

        if (mockExceptionThrown) {
          throw Exception();
        } else if (mockPlatformExceptionThrown) {
          throw PlatformException(code: 'UNKNOWN');
        }

        switch (call.method) {
          case 'FirebasePerformance#isPerformanceCollectionEnabled':
            return true;
          case 'FirebasePerformance#setPerformanceCollectionEnabled':
            return call.arguments['enable'];
          case 'FirebasePerformance#newTrace':
            return null;
          case 'FirebasePerformance#newHttpMetric':
            return null;
          default:
            return true;
        }
      });

      performance = MethodChannelFirebasePerformance(app: app);
      mockPerformance = TestMethodChannelFirebasePerformance(app);
    });
  });

  setUp(() async {
    mockPlatformExceptionThrown = false;
    mockExceptionThrown = false;
    log.clear();
    MethodChannelFirebasePerformance.clearState();
  });

  tearDown(() async {
    mockPlatformExceptionThrown = false;
    mockExceptionThrown = false;
  });

  test('instance', () {
    final testPerf = MethodChannelFirebasePerformance.instance;

    expect(testPerf, isA<FirebasePerformancePlatform>());
  });

  test('delegateFor', () {
    final testPerf = TestMethodChannelFirebasePerformance(Firebase.app());
    final result = testPerf.delegateFor(app: Firebase.app());

    expect(result, isA<FirebasePerformancePlatform>());
    expect(result.app, isA<FirebaseApp>());
  });

  group('isPerformanceCollectionEnabled', () {
    test('should call delegate method successfully', () {
      performance.isPerformanceCollectionEnabled();

      expect(log, <Matcher>[
        isMethodCall('FirebasePerformance#isPerformanceCollectionEnabled',
            arguments: {'handle': 0})
      ]);
    });

    test(
        'catch a [PlatformException] error and throws a [FirebaseException] error',
        () async {
      mockPlatformExceptionThrown = true;

      await testExceptionHandling(
          'PLATFORM', performance.isPerformanceCollectionEnabled);
    });
  });

  group('setPerformanceCollectionEnabled', () {
    test('should call delegate method successfully', () {
      performance.setPerformanceCollectionEnabled(true);

      expect(log, <Matcher>[
        isMethodCall('FirebasePerformance#setPerformanceCollectionEnabled',
            arguments: {'handle': 0, 'enable': true})
      ]);
    });

    test(
        'catch a [PlatformException] error and throws a [FirebaseException] error',
        () async {
      mockPlatformExceptionThrown = true;

      await testExceptionHandling(
          'PLATFORM', () => performance.setPerformanceCollectionEnabled(true));
    });
  });

  group('newTrace', () {
    test('should call delegate method successfully', () async {
      final trace = await performance.newTrace('trace-name');

      expect(trace, isA<MethodChannelTrace>());

      expect(log, <Matcher>[
        isMethodCall('FirebasePerformance#newTrace',
            arguments: {'handle': 0, 'traceHandle': 1, 'name': 'trace-name'})
      ]);
    });

    test(
        'catch a [PlatformException] error and throws a [FirebaseException] error',
        () async {
      mockPlatformExceptionThrown = true;

      await testExceptionHandling(
          'PLATFORM', () => performance.newTrace('trace-name'));
    });
  });

  group('newHttpMetric', () {
    test('should call delegate method successfully', () async {
      final httpMetric =
          await performance.newHttpMetric('http-metric-url', HttpMethod.Get);

      expect(httpMetric, isA<MethodChannelHttpMetric>());

      expect(log, <Matcher>[
        isMethodCall(
          'FirebasePerformance#newHttpMetric',
          arguments: {
            'handle': 0,
            'httpMetricHandle': 1,
            'url': 'http-metric-url',
            'httpMethod': HttpMethod.Get.toString(),
          },
        )
      ]);
    });

    test(
        'catch a [PlatformException] error and throws a [FirebaseException] error',
        () async {
      mockPlatformExceptionThrown = true;

      await testExceptionHandling('PLATFORM',
          () => performance.newHttpMetric('http-metric-url', HttpMethod.Get));
    });
  });
}

class TestMethodChannelFirebasePerformance
    extends MethodChannelFirebasePerformance {
  TestMethodChannelFirebasePerformance(FirebaseApp app) : super(app: app);
}