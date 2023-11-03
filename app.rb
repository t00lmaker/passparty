
require 'sinatra'
require 'sinatra/json'
require 'sinatra/reloader' if development?

require 'rqrcode'

get '/guest' do
  erb :guest
end

post '/guest' do
  # Handle the form submission here
  # You can access the form fields with params[:name], params[:cell_phone], etc.
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