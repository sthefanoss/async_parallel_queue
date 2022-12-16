import 'package:async_parallel_queue/async_parallel_queue.dart';

void main() async {
  final queue = AsyncParallelQueue<int>(workers: 3, verbose: true);
  // final subscription = queue.debugStream.listen(print);

  for (int i = 1; i <= 10; i++) {
    queue
        .registerCallback(i, () async {
          await Future.delayed(Duration(milliseconds: 100 * i));
          if (i == 5) {
            queue.cancelCallback(8); // will not be removed because already started when 5 runs
            queue.cancelCallback(9); // will be removed
            throw 'Number 5 exception';
          }
          return 'Result $i';
        })
        .then(print)
        .catchError(print); // show exception thrown by callback
  }

  queue.cancelCallback(6); // remove 6 before it runs
  // subscription.cancel();
  print('finish');
}
