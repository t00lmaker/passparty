require 'securerandom'

require 'sinatra'
require 'sinatra/json'
require 'sinatra/reloader' if development?

require 'rqrcode'
require 'otr-activerecord'
require './models/guest'

OTR::ActiveRecord.configure_from_file! "config/database.yml"
OTR::ActiveRecord.establish_connection!

get '/guest' do
  erb :guest
end

post '/guest' do
  @guest = Guest.new(
    name: params[:name], 
    email: params[:email], 
    phone: params[:phone], 
    has_children: params[:has_children] ? true : false, 
    salt: SecureRandom.uuid.split("-")[0]
  )

  if @guest.save
    "Guest saved successfully."
  else
    "There was an error saving the guest: " + @guest.errors.full_messages.join(", ")
  end
end

get '/generate_qr/:name' do
  name = params['name']
  qrcode = RQRCode::QRCode.new("http://yourapi.com/confirm/#{name}")
  # This will output the QR code as a string, but in a real application you would want to render it as an image or PDF
  "QR Code for #{name}: #{qrcode.as_svg}"
end

get '/confirm/:name' do
  name = params['name']
  if guests[name]
    "Guest #{name} has already been confirmed."
  elsif guests.has_key?(name)
    guests[name] = true
    "Guest #{name} confirmed."
  else
    "No guest found with name #{name}."
  end
end

get '/status/:name' do
  name = params['name']
  if guests[name]
    "Guest #{name} has been confirmed."
  elsif guests.has_key?(name)
    "Guest #{name} has not been confirmed."
  else
    "No guest found with name #{name}."
  end
end