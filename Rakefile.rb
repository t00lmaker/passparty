# Rakefile
require './app' 
require "bundler/setup"
load "tasks/otr-activerecord.rake"

namespace :db do
  task :environment do
    require_relative "app"
  end
end