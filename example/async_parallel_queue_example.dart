import 'package:async_parallel_queue/async_parallel_queue.dart';

void main() {
  final queue = AsyncParallelQueue<int>(workers: 3, verbose: true);

  for (int i = 1; i <= 10; i++) {
    queue
        .registerCallback(i, () async {
          print('Starting $i');

          await Future.delayed(Duration(seconds: 1));
          if (i == 5) throw 'Number five exception';

          return i;
        })
        .then((value) => print('finishing $value')) // use value returned by callback
        .catchError((e) => print('error $e for $i')); // show exception thrown by callback
  }

  queue.cancelCallback(6); // remove 6 before it runs
}
