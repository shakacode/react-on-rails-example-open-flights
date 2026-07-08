source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 8.1'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 8.0'
gem 'minitest', '< 7'

gem 'brakeman'
gem 'bcrypt'
gem 'bundler-audit'
gem 'fast_jsonapi'
gem 'figaro'
gem 'sass-rails', '~> 6.0'
gem 'sendgrid-ruby'
gem 'sidekiq'
gem 'uglifier', '>= 1.3.0'
gem 'graphql'
gem 'graphql-batch'
gem 'graphiql-rails', group: :development
gem 'pry'

group :development, :test do
  gem 'factory_bot_rails'
  gem 'rspec-rails'
  gem 'rspec_junit_formatter'
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do

  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.11'

  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.1.0'
end

gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem "react_on_rails", "= 17.0.0.rc.6"

gem "shakapacker", "= 10.2.0"
