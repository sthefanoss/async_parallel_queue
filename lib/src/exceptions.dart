import 'async_parallel_queue_base.dart';
import 'package:quiver/core.dart';

/// Error thrown when callback is registered with a key already in use in [AsyncParallelQueue.registerCallback].
class KeyAlreadyInUseException<K extends Object> implements Exception {
  const KeyAlreadyInUseException(this.key);
  final K key;

  @override
  String toString() => 'KeyAlreadyInUseException(key: $key)';

  @override
  bool operator ==(dynamic other) {
    if (other is! KeyAlreadyInUseException) return false;
    return key == other.key;
  }

  @override
  int get hashCode => hash2(key, 'key-exception');
}

/// Error thrown when callback is cancelled by [AsyncParallelQueue.cancelCallback].
class CallbackCancelledException<K extends Object> implements Exception {
  const CallbackCancelledException(this.key);
  final K key;

  @override
  String toString() => 'CallbackCancelledException(key: $key)';

  @override
  bool operator ==(dynamic other) {
    if (other is! CallbackCancelledException) return false;
    return key == other.key;
  }

  @override
  int get hashCode => hash2(key, 'cancel-exception');
}
