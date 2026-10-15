class ResetPasswordWorker
  include Sidekiq::Worker

  def perform(email, token, root_url = ENV.fetch('ROOT_URL'))
    return unless ActionMailer::Base.perform_deliveries

    ResetPasswordMailer.call(email, token, root_url).deliver
  end
end
