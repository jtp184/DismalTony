source 'https://rubygems.org'
git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Specify your gem's dependencies in tony.gemspec
gemspec

group :development do
  gem 'guard', require: false
  gem 'guard-bundler', require: false
  gem 'guard-rubycritic', require: false
  gem 'hanna-nouveau', require: false
  gem 'pry', '~> 0.10.4'
  gem 'rdoc', require: false
end

group :runtime do
  gem 'ParseyParse', git: 'https://github.com/jtp184/ParseyParse'
end
