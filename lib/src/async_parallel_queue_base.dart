import 'dart:async';
import 'dart:developer';

class AsyncParallelQueue<K extends Object> {
  AsyncParallelQueue({
    this.workers = 5,
    this.verbose = false,
  }) : assert(workers > 0);

  /// Current number of callbacks running in parallel.
  int _runningCallbacks = 0;

  /// Callback queue. Order matters!
  final _waitingCallbacks = <K>[];

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
      _updateQueueStatus('[$key] start running.');

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
    if (!_waitingCallbacks.contains(key)) return _updateQueueStatus('[$key] is not in queue.');

    _completerByKey.remove(key);
    _waitingCallbacks.remove(key);
    _completerByKey[key]?.completeError(CallbackCancelledException._(key));
    _updateQueueStatus('[$key] left the queue.');
  }

  void _updateQueueStatus(String event) {
    final formattedEvent = _formatEvent(event);
    _streamController.sink.add(formattedEvent);
    if (!verbose) return;
    log(formattedEvent, name: 'AsyncParallelQueue');
  }

  String _formatEvent(String event) {
    return '$event | Running: $_runningCallbacks.'
        ' Waiting: ${_waitingCallbacks.length}.';
  }
}

/// Error thrown when callback is cancelled by [cancelCallback].
class CallbackCancelledException {
  const CallbackCancelledException._(this.key);
  final Object key;

  @override
  String toString() => 'CallbackCancelledException(key: $key)';
}
