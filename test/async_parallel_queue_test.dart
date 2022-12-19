import 'dart:async';

import 'package:async_parallel_queue/async_parallel_queue.dart';
import 'package:test/test.dart';

void main() {
  late AsyncParallelQueue<int> dut;
  late StreamController<int> controller;
  late StreamController errorController;

  test('callbacks should be executed in order with 1 worker', () {
    dut = AsyncParallelQueue(workers: 1);
    controller = StreamController();

    for (int i = 0; i < 10; i++) {
      dut.registerCallback(i, () => i).then(controller.add);
    }

    expect(controller.stream, emitsInOrder([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]));
  });

  test('callbacks should be executed in order with 5 workers', () {
    dut = AsyncParallelQueue(workers: 5);
    controller = StreamController();

    for (int i = 0; i < 10; i++) {
      dut.registerCallback(i, () => i).then(controller.add);
    }

    expect(controller.stream, emitsInOrder([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]));
  });

  test('should execute async callbacks in order', () {
    dut = AsyncParallelQueue();
    controller = StreamController();

    for (int i = 0; i < 10; i++) {
      dut.registerCallback(i, () async {
        await Future.delayed(Duration(milliseconds: 100));
        return i;
      }).then(controller.add);
    }

    expect(controller.stream, emitsInOrder([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]));
  });

  test('should emmit errors in order', () {
    dut = AsyncParallelQueue(workers: 1);
    controller = StreamController();
    errorController = StreamController();

    for (int i = 0; i < 10; i++) {
      dut
          .registerCallback(i, () async {
            await Future.delayed(Duration(milliseconds: 100));
            if (i == 5 || i == 7) {
              throw i.toString();
            }
            return i;
          })
          .then(controller.add)
          .catchError(errorController.add);
    }

    expect(controller.stream, emitsInOrder([0, 1, 2, 3, 4, 6, 8, 9]));
    expect(errorController.stream, emitsInOrder(['5', '7']));
  });

  test("should stop callback in queue with cancelCallback", () {
    dut = AsyncParallelQueue(workers: 1, verbose: true);
    controller = StreamController();
    errorController = StreamController();

    for (int i = 0; i <= 5; i++) {
      dut
          .registerCallback(i, () async {
            await Future.delayed(Duration(milliseconds: 100));
            if (i == 1) {
              dut.cancelCallback(3); // not running with 1
              dut.cancelCallback(5); // not running with 1
            }
            return i;
          })
          .then(controller.add)
          .catchError(errorController.add);
    }

    expect(controller.stream, emitsInOrder([0, 1, 2, 4]));
    expect(errorController.stream, emitsInOrder([CallbackCancelledException(3), CallbackCancelledException(5)]));
  });

  test("shouldn't stop callback already running with cancelCallback", () {
    dut = AsyncParallelQueue(workers: 2, verbose: true);
    controller = StreamController();
    errorController = StreamController();

    for (int i = 0; i <= 5; i++) {
      dut
          .registerCallback(i, () async {
            await Future.delayed(Duration(milliseconds: 100));
            if (i == 2) {
              dut.cancelCallback(3); // already running with 2
              dut.cancelCallback(5); // not running with 2
            }
            return i;
          })
          .then(controller.add)
          .catchError(errorController.add);
    }

    expect(controller.stream, emitsInOrder([0, 1, 2, 3, 4]));
    expect(errorController.stream, emitsInOrder([CallbackCancelledException(5)]));
  });

  test('should toggle between complete and cancel callback', () {
    dut = AsyncParallelQueue(workers: 1);
    controller = StreamController();
    errorController = StreamController();

    for (int i = 0; i < 11; i++) {
      dut
          .registerCallback(i, () async {
            await Future.delayed(Duration(milliseconds: 100));
            if (i % 2 == 0) {
              dut.cancelCallback(i + 1); // does nothing
            }
            return i;
          })
          .then(controller.add)
          .catchError(errorController.add);
    }

    expect(controller.stream, emitsInOrder([0, 2, 4, 6, 8, 10]));
    expect(
      errorController.stream,
      emitsInOrder(
        [
          CallbackCancelledException(1),
          CallbackCancelledException(3),
          CallbackCancelledException(5),
          CallbackCancelledException(7),
          CallbackCancelledException(9),
        ],
      ),
    );
  });
}
