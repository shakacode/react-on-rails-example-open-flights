module Resettable
  extend ActiveSupport::Concern

  included do
    before_action :check_email, only: :reset
  end
  
  # TODO: Clean up this method
  def forgot_password
    user = User.find_by(email: params[:email])

    if user
      user.generate_password_token!
      send_reset_password_email(user.email, user.reload.reset_password_token)
    end

    render json: { success: true }, status: 204
  end
  
  # TODO: Clean up this method
  def reset_password
    user = User.find_by(reset_password_token: params[:token])

    return invalid_reset unless user&.password_token_valid?

    if user.reset_password!(params[:password])
      render json: { success: true }, status: 204
    else
      render json: { error: user.errors.full_messages }, status: 422
    end
  end

  private

  # Send the password reset email.
  # @param email [String]
  # @param token [String]
  #
  # @return [Nil]
  def send_reset_password_email(email, token)
    ResetPasswordWorker.perform_async(email, token, password_reset_root_url)
  end

  def password_reset_root_url
    value = ENV['CPLN_GLOBAL_ENDPOINT'].presence || ENV.fetch('ROOT_URL')
    value = "https://#{value}" unless value.include?('://')
    uri = URI.parse(value)
    allowed_scheme = Rails.env.production? ? uri.scheme == 'https' : %w[http https].include?(uri.scheme)
    unless allowed_scheme && uri.host.present? && uri.userinfo.nil? &&
           uri.query.nil? && uri.fragment.nil? && ['', '/'].include?(uri.path)
      raise ArgumentError, 'Password reset origin must be a valid HTTPS origin'
    end
    uri.to_s.chomp('/')
  end

  def check_email
    render json: { error: 'Invalid email' }, status: 422 if params[:email].blank?
  end

  def invalid_reset
    render json: { error:  'The link has expired.' }, status: 404
  end
end
