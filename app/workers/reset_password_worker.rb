class ResetPasswordWorker
  include Sidekiq::Worker

  def perform(email, token, root_url)
    ResetPasswordMailer.call(email, token, root_url).deliver
  end
end
