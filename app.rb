require 'securerandom'

require 'sinatra'
require 'sinatra/json'
require 'sinatra/reloader' if development?

require 'rqrcode'
require 'otr-activerecord'
require './models/guest'
require 'csv'


OTR::ActiveRecord.configure_from_file! "config/database.yml"
OTR::ActiveRecord.establish_connection!

URL = ENV["APP_URL"] || "localhost:9292" 

get '/guest' do
  @guest = Guest.new
  erb :guest
end

get '/guests/import' do
  erb :guests_import
end

get '/guests/export' do
  content_type 'application/csv'
  attachment "guests.csv"

  CSV.generate do |csv|
    csv << ["Name", "Email", "Phone", "Has Children", "Is Active"]
    Guest.all.each do |guest|
      csv << [guest.name, guest.email, guest.phone, guest.has_children, guest.is_active]
    end
  end
end

get '/guests/confirm/:salt' do
  @guest = Guest.find_by(salt: params[:salt])
  @message = "Confirme os dados abaixo para confirmar a entrada do convidado."
  @message_type = "primary"
  @salt = params[:salt]
  erb :guest_show
end

get '/guests/:id' do
  @guest = Guest.find(params[:id])
  qrcode = RQRCode::QRCode.new("#{URL}/guests/confirm/#{@guest[:salt]}")
  @qrcode_svg = qrcode.as_svg(
    color: "000",
    shape_rendering: "crispEdges",
    module_size: 11,
    standalone: true,
    use_path: true
  )
  erb :guest_show
end

get '/guests/:id/edit' do
  @guest = Guest.find(params[:id])
  erb :guest
end

post '/guests/confirm/:salt' do
  @guest = Guest.find_by(salt: params[:salt])
  @message = "Entrada confirmada com sucesso!"
  @message_type = "success"
  erb :guest_show
end

post '/guest' do
  @guest = Guest.new(
    name: params[:name], 
    email: params[:email], 
    phone: params[:phone], 
    has_children: params[:has_children] ? true : false, 
    is_active: true, 
    salt: SecureRandom.uuid.split("-")[0]
  )

  if @guest.save
    @message = "Convidado salvo com suecesso!"
    @message_type = "success"
    erb :guest_show
  else
    @message = "Alguns problemas foram encontrados ao tentar salvar o convidado: " + @guest.errors.full_messages.join(", ")
    @message_type = "danger"
    erb :guest
  end
end


post '/guests/import' do
  if params[:file] && params[:file][:tempfile]
    CSV.foreach(params[:file][:tempfile], headers: true) do |row|
      print(row)
      guest = Guest.create(row.to_hash.merge({is_active: true, salt: SecureRandom.uuid.split("-")[0]}))
      unless guest.valid? 
        puts  guest.errors.objects.first.full_message
      end
    end
  end

  redirect '/guests'
end

get '/guests' do
  @guests = Guest.all
  erb :guests
end
