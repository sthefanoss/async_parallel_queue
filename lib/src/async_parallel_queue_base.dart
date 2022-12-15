import 'dart:async';
import 'dart:developer';

class AsyncParallelQueue<K> {
  AsyncParallelQueue({
    this.workers = 5,
    this.verbose = false,
  }) : assert(workers > 0);

  /// Current number of callbacks running in parallel.
  int _runningCallbacks = 0;

  /// Callback queue. Order matters!
  final _waitingCallbacks = [];

  /// Used only in cancellation.
  final _completerByKey = <K, Completer>{};

  /// Used to notify all listeners when queue is updated.
  final _streamController = StreamController<String>.broadcast();

  /// Listen to [debugStream] to receive queue status updates.
  Stream<String> get debugStream => _streamController.stream;

  /// Workers count. Max number of async callbacks to be running in parallel.
  final int workers;

  /// Logs all updates on console.
  final bool verbose;

  /// Register a callback to be executed when there is a available worker.
  /// Can wait for result. Key is required and is used for know callback position on queue and for cancellation.
  Future<T> registerCallback<T>(K key, FutureOr<T> Function() callback) async {
    final completer = Completer<T>();

    _waitingCallbacks.add(key);
    _completerByKey[key] = completer;

    late StreamSubscription<String> subscription; // created before to be cancelled inside
    subscription = _streamController.stream.listen((_) async {
      // all workers busy
      if (_runningCallbacks >= workers) return;
      final index = _waitingCallbacks.indexOf(key);

      // removed from queue by [cancelCallback]
      if (index == -1) return subscription.cancel();

      // not the first in the queue
      if (index != 0) return;
      _runningCallbacks++;
      subscription.cancel();
      _completerByKey.remove(key);
      _waitingCallbacks.remove(key);
      _streamController.add(
        '[$key] is running.'
        ' Running callbacks: $_runningCallbacks.'
        ' Waiting callbacks: ${_waitingCallbacks.length}.',
      );

      try {
        completer.complete(await callback());
        _runningCallbacks--;
        _updateQueueStatus('[$key] completed with success.');
      } catch (error) {
        completer.completeError(error);
        _runningCallbacks--;
        _updateQueueStatus('[$key] completed with error.');
      }
    });

    _updateQueueStatus('[$key] entered the queue.');
    return completer.future;
  }

  /// Cancels a callback waiting in queue. You can not cancel a callback already running!
  void cancelCallback(K key) {
    _waitingCallbacks.remove(key);
    _completerByKey[key]?.completeError(CallbackCancelledException());

    if (verbose) {
      log(
        '[$key] left the queue.'
        ' Running: $_runningCallbacks.'
        ' Waiting: ${_waitingCallbacks.length}.',
        name: 'ParallelQueue',
      );
    }
  }

  void _updateQueueStatus(String message) {
    if (verbose) {
      log(
        '$message Running: $_runningCallbacks.'
        ' Waiting: ${_waitingCallbacks.length}.',
        name: 'ParallelQueue',
      );
    }
    _streamController.add(message);
  }
}

/// Error thrown when callback is cancelled by [cancelCallback].
class CallbackCancelledException {}
