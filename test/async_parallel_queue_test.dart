import 'package:async_parallel_queue/async_parallel_queue.dart';
import 'package:test/test.dart';

void main() {
  final queue = AsyncParallelQueue();

  test('calculate', () {
    queue.registerCallback(0, () {});
  });
}
