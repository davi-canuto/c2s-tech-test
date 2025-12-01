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
  def log_error(exception, context: {})
    Rails.logger.error format_error_message(exception, context)

    # TODO: Uncomment when adding error tracking service
    # Rollbar.error(exception, context) if defined?(Rollbar)
    # Sentry.capture_exception(exception, extra: context) if defined?(Sentry)
  end

  # Handles error: logs + sets error message
  def handle_error(exception, context: {}, user_message: nil)
    log_error(exception, context:)

    @error_message = user_message || default_error_message(exception)
    nil
  end

  private

  def format_error_message(exception, context)
    message = [
      "=" * 80,
      "Error: #{exception.class}",
      "Message: #{exception.message}",
      ("Context: #{context.inspect}" if context.any?),
      "Backtrace:",
      exception.backtrace&.first(10)&.join("\n"),
      "=" * 80
    ].compact.join("\n")

    message
  end

  def default_error_message(exception)
    case exception
    when ActiveRecord::RecordInvalid
      exception.record.errors.full_messages.join(', ')
    when ActiveRecord::RecordNotFound
      "Record not found"
    else
      "An error occurred: #{exception.message}"
    end
  end
end
