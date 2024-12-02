module ApiHelper
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound,        with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid,         with: :render_record_invalid
    rescue_from ActionController::RoutingError,      with: :render_not_found
    rescue_from AbstractController::ActionNotFound,  with: :render_not_found
    rescue_from ActionController::ParameterMissing,  with: :render_parameter_missing
  end

  def responder(status, message = nil, additional_data = {})
    status_code = Rack::Utils::SYMBOL_TO_STATUS_CODE[status]
    status_message = ::Rack::Utils::HTTP_STATUS_CODES[status_code]

    response = {
      success: status_code.to_s.start_with?('2'),
      code: status_code,
      status: status_message,
      message: message || status_message
    }

    render json: response.merge(additional_data), status: status
  rescue StandardError => e
    logger.error("Error in responder: #{e.message}")
    render json: {
      success: false,
      code: 500,
      status: 'Internal Server Error',
      message: "An unexpected error occurred. Error: #{e.message}"
    }, status: :internal_server_error
  end

  private

  def render_error(exception)
    raise exception if Rails.env.test?

    return render_not_found(exception) if exception.cause.is_a?(ActiveRecord::RecordNotFound)

    responder(:internal_server_error, "Internal server error") unless performed?
  end

  def render_not_found(exception)
    responder(:not_found, "Record or object not found")
  end

  def render_record_invalid(exception)
    responder(:bad_request, exception.record.errors.full_messages.to_sentence)
  end

  def render_parameter_missing(exception)
    responder(:bad_request, "Missing Parameters")
  end
end
