# config.ru
require './app'

use OTR::ActiveRecord::ConnectionManagement

run Sinatra::Application 