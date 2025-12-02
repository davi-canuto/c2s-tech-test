# frozen_string_literal: true

# ErrorHandler - Centralizes error logging and reporting
#
# This module provides consistent error handling across services.
# In production, replace Rails.logger calls with external error tracking:
#   - Rollbar.error(exception, context)
#   - Sentry.capture_exception(exception, extra: context)
#   - Honeybadger.notify(exception, context: context)
#
# Usage:
#   class MyService
#     include ErrorHandler
#
#     def call
#       # ...
#     rescue StandardError => e
#       handle_error(e, context: { user_id: @user.id })
#     end
#   end
#
module ErrorHandler
  def handle_error(exception, context: {}, user_message: nil)
    log_error(exception, context: context)
    @error_message = user_message || exception.message
    nil
  end

  def log_error(exception, context: {})
    Rails.logger.error format_error_message(exception, context)

    # TODO: Uncomment when adding error tracking service
    # Rollbar.error(exception, context) if defined?(Rollbar)
    # Sentry.capture_exception(exception, extra: context) if defined?(Sentry)
  end

  private

  def format_error_message(exception, context)
    {
      error_class: exception.class.name,
      error_message: exception.message,
      backtrace: exception.backtrace&.first(5),
      context: context
    }.to_json
  end
end
