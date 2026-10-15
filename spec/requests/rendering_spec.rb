require 'rails_helper'

RSpec.describe 'Rendering', type: :request, server_rendering: true do
  it 'serves the flight application with its client entrypoint once' do
    get '/'

    expect(response).to have_http_status(:ok)
    scripts = Nokogiri::HTML(response.body).css('script[src]').map { |script| script['src'] }
    expect(scripts.grep(%r{/packs-test/.*index.*\.js})).not_to be_empty
    expect(scripts).to eq(scripts.uniq)
  end

  it 'renders the greeting on the server' do
    get '/hello_world'

    expect(response).to have_http_status(:ok)
    expect(Nokogiri::HTML(response.body).at_css('h3').text).to eq('Hello, Stranger!')
  end
end
