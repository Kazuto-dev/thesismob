/// Counts attempts per key in a sliding window, such as code redemptions
/// per account, so a code cannot be guessed by trying many.
class RateLimiter {
  RateLimiter(this.limit, this.window, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final int limit;
  final Duration window;
  final DateTime Function() _now;
  final _hits = <String, List<DateTime>>{};

  /// Records an attempt for [key]; false when it is over the limit.
  bool allow(String key) {
    final now = _now();
    final since = now.subtract(window);
    final hits = (_hits[key] ?? [])..removeWhere((t) => t.isBefore(since));
    if (hits.length >= limit) {
      _hits[key] = hits;
      return false;
    }
    _hits[key] = hits..add(now);
    if (_hits.length > 10000) _prune(since);
    return true;
  }

  void _prune(DateTime since) {
    _hits.removeWhere((_, hits) => hits.every((t) => t.isBefore(since)));
  }
}
