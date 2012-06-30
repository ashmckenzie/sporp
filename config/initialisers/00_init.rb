require 'bundler/setup'
Bundler.require(:default, :development)

require 'active_support/dependencies'
ActiveSupport::Dependencies.autoload_paths << File.expand_path('../../../lib', __FILE__)

require 'json'
require 'pathname'
require 'logger'
