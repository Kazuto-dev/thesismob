/// A failure the API reports to the app: an HTTP status, a stable code the
/// app can act on, and a message a person can read.
class ApiError implements Exception {
  ApiError(this.status, this.code, this.message, [this.details = const {}]);

  ApiError.badRequest(String message) : this(400, 'bad_request', message);
  ApiError.unauthorized([String message = 'Sign in first.'])
    : this(401, 'unauthorized', message);
  ApiError.forbidden([String message = 'You cannot do that.'])
    : this(403, 'forbidden', message);
  ApiError.notFound([String message = 'Not found.'])
    : this(404, 'not_found', message);

  final int status;
  final String code;
  final String message;
  final Map<String, Object?> details;

  Map<String, Object?> toJson() => {
    'error': {'code': code, 'message': message, ...details},
  };

  @override
  String toString() => 'ApiError($status $code: $message)';
}
