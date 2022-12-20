# Async Parallel Queue

Library to enqueue async callbacks to be executed in order. You can await for they completion and/or cancel the execution by id.

## Usage
Callbacks registered will be executed in order. You can chose workers count to run more than one callbacks at once.

```dart
import 'package:async_parallel_queue/async_parallel_queue.dart';

void main() {
  final queue = AsyncParallelQueue<int>(
    workers: 1, // amount of callbacks running in parallel
    verbose: true, // enables queue status logs
  );

  queue.registerCallback(1, () { print('foo'); });
  queue.registerCallback(2, () { print('boo');  });
  queue.registerCallback(3, () async {
    await Future.delayed(Duration.zero);
    print('bar'); 
  });
}
```

### Waiting for completion
You can use registerCallback just as funcion wrapper and await for its result. Note: key is required.

```dart
import 'package:async_parallel_queue/async_parallel_queue.dart';

Future<int> dummyHttpRequest() async {
  await Future.delayed(Duration.zero);
  return 42;
}

void main() async {
  final queue = AsyncParallelQueue();

  final response = await queue.registerCallback(
    DateTime.now(),
    dummyHttpRequest,
  );

  print('The number is $response');
}
}
```
You can use .then to enqueue multiple requests and use they result as well.

```dart
import 'package:async_parallel_queue/async_parallel_queue.dart';

Future<String> dummyHttpRequest(String response) async {
  await Future.delayed(Duration.zero);
  return response;
}

void main() async {
  final queue = AsyncParallelQueue(workers: 1);

  queue.registerCallback<String>(1, () {
    return dummyHttpRequest('foo again');
  }).then(print);

  queue.registerCallback<String>(2, () {
    return dummyHttpRequest('boo again');
  }).then(print);

  queue.registerCallback<String>(3, () {
    return dummyHttpRequest('bar again');
  }).then(print);
}
```

### Typing
You can specify return type. Callback is FutureOr\<T>, witch means it can be sync our async. 
```dart
import 'package:async_parallel_queue/async_parallel_queue.dart';

void main() async {
  final queue = AsyncParallelQueue<int>(
    workers: 1, // amount of callbacks running in parallel
    verbose: true, // enables queue status logs
  );
  var message = '';

  queue.registerCallback<String>(2, () {
    return 'the answer';
  }).then((value) => message = '$message $value');

  queue.registerCallback<String>(3, () async {
    await Future.delayed(Duration.zero);
    return 'is';
  }).then((value) => message = '$message $value');

  await queue.registerCallback<int>(1, () {
    return 42;
  }).then((value) => message = '$message $value');

  print(message);
}
```

### Cancel callback
You can always cancel a callback in queue. It will unregister the callback from the queue and throw a CallbackCancelledException. **You can not stop a callback already running.**

```dart
import 'package:async_parallel_queue/async_parallel_queue.dart';

Future<String> dummyHttpRequest(String response) async {
  await Future.delayed(Duration.zero);
  return response;
}

void main() async {
  final queue = AsyncParallelQueue(workers: 1);

  queue.registerCallback<String>(1, () {
    return dummyHttpRequest('foo once more');
  }).then(print);

  queue.registerCallback<String>(2, () {
    queue.cancelCallback(3); //cancels callback 3
    return dummyHttpRequest('boo once more');
  }).then(print);

  queue.registerCallback<String>(3, () {
    return dummyHttpRequest('bar once more');
  }).then(print).catchError((error) {
    print(error.runtimeType);
  });
}
```
As all callbacks are registered synchronously, you can stop cb 3 inside cb 2. 

## Beware using the same key
Key is used in this library for prevent a callback to run if it is still on queue. If you try to register a new callback with same key of one callback inside queue, a KeyAlreadyInUseException will be thrown. 

```dart
void main() {
  void main() async {
  final queue = AsyncParallelQueue(workers: 1);

  queue.registerCallback('same key', () {});
  queue.registerCallback('same key', () {}); // throws KeyAlreadyInUseException
}
```
At last you can reuse a key if the function is not on queue or is running. Well, the function leaves the queue to starting running anyway!

```dart
void main() async {
  final queue = AsyncParallelQueue(workers: 1);

  queue.registerCallback('same key', () {
    print('foo for the last time');

    queue.registerCallback('same key', () {
      print('boo for the last time');
      
      queue.registerCallback('same key', () {
        print('bar for the last time');
      });
    });
  });
}
```
Why would you reuse a key?! I don't know, but you can.