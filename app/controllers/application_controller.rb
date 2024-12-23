class ApplicationController < ActionController::API
  include Pagy::Backend
  include ApiHelper

  before_action :authenticate_user!

  attr_reader :current_user

  private

  def authenticate_user!
    user_id = params[:user_id] || params[:id]
    params.require(:user_id)

    @current_user = User.find_by(id: user_id)
    unauthorized_error unless @current_user
  end

  def unauthorized_error
    responder(:unauthorized, "Authentication failed. Please provide a valid user ID.")
  end

  def per_page
    params[:per_page] || 10
  end
end
