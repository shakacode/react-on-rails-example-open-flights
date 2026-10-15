require 'rails_helper'

RSpec.describe 'Password reset requests', type: :request do
  around do |example|
    original = ENV.to_h.slice('ROOT_URL', 'CPLN_GLOBAL_ENDPOINT')
    ENV['ROOT_URL'] = 'https://reset.example.invalid'
    ENV.delete('CPLN_GLOBAL_ENDPOINT')
    example.run
  ensure
    %w[ROOT_URL CPLN_GLOBAL_ENDPOINT].each { |key| ENV.delete(key) }
    ENV.update(original)
  end

  it 'returns the same response for known and unknown email addresses' do
    user = create(:user)
    allow(ResetPasswordWorker).to receive(:perform_async)

    post '/api/v1/auth/password/forgot', params: { email: user.email }
    known_response = [response.status, response.body]
    post '/api/v1/auth/password/forgot', params: { email: 'unknown@example.invalid' }

    expect([response.status, response.body]).to eq(known_response)
    expect(response).to have_http_status(:no_content)
    expect(ResetPasswordWorker).to have_received(:perform_async).once
  end

  it 'normalizes a platform hostname to an HTTPS origin' do
    ENV['CPLN_GLOBAL_ENDPOINT'] = 'rails-preview.cpln.app/'
    expect(Api::V1::AuthController.new.send(:password_reset_root_url)).to eq('https://rails-preview.cpln.app')
  end

  it 'fails consistently before changing a token when the reset origin is invalid' do
    user = create(:user)
    ENV['ROOT_URL'] = 'https://reset.example.invalid/path'
    [user.email, 'unknown@example.invalid'].each do |email|
      expect { post '/api/v1/auth/password/forgot', params: { email: email } }.to raise_error(ArgumentError)
    end
    expect(user.reload.reset_password_token).to be_nil
  end

  it 'skips queued mail when delivery is disabled and the sender is unconfigured' do
    original_sender = ENV.delete('DEFAULT_FROM_EMAIL')
    allow(ActionMailer::Base).to receive(:perform_deliveries).and_return(false)
    expect { ResetPasswordWorker.new.perform('test@example.invalid', 'token', ENV.fetch('ROOT_URL')) }.not_to raise_error
  ensure
    ENV['DEFAULT_FROM_EMAIL'] = original_sender if original_sender
  end

  it 'rejects an insecure password reset origin in production' do
    allow(Rails.env).to receive(:production?).and_return(true)
    ENV['CPLN_GLOBAL_ENDPOINT'] = 'http://rails-preview.cpln.app'
    expect { Api::V1::AuthController.new.send(:password_reset_root_url) }.to raise_error(ArgumentError)
  end

  it 'rejects a reset origin containing a path or user information' do
    ['https://preview.cpln.app/reset', 'https://user@preview.cpln.app'].each do |origin|
      ENV['CPLN_GLOBAL_ENDPOINT'] = origin
      expect { Api::V1::AuthController.new.send(:password_reset_root_url) }.to raise_error(ArgumentError)
    end
  end
end
