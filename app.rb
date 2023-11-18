require 'securerandom'

require 'sinatra'
require 'sinatra/json'
require 'sinatra/reloader' if development?

require 'rqrcode'
require 'otr-activerecord'
require './models/guest'
require './models/confirmation'
require 'csv'
require 'i18n'

configure do
  I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
  I18n.load_path = Dir[File.join(settings.root, 'locales', '*.yml')]
  I18n.backend.load_translations
end

OTR::ActiveRecord.configure_from_file! "config/database.yml"
OTR::ActiveRecord.establish_connection!

URL = ENV["APP_URL"] || "localhost:9292" 


get '/' do
  @guest = Guest.new
  erb :index
end

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
    csv << ["id", "Convidado", "Faixa Etária" "Telefone"]
    Guest.all.each do |guest|
      csv << [guest.id, guest.name, guest.age, guest.phone]
    end
  end
end

get '/guests/confirm/:salt' do
  @guest = Guest.find_by(salt: params[:salt])
  if(@guest and @guest.is_active and not @guest.confirmation  )
    @message = "Confirme os dados abaixo para confirmar a entrada do convidado."
    @message_type = "primary"
    @salt = params[:salt]
    erb :guest_show
  else
    @message = "Usuário não encontrado!"
    @message_type = "warning"
    erb :not_found
  end
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

get '/api/guest/:salt' do
  content_type :json
  @guest = Guest.find_by(salt: params[:salt])
  if @guest
    @guest.to_json(include: :confirmation)
  else
    status 404
    json({message: "Usuário não encontrado!"})
  end
end

post '/api/guests/confirm/:salt' do
  @guest = Guest.find_by(salt: params[:salt])
  if @guest
    if not @guest.is_active
      status 420
      json({message: "Usuário não está ativo!"})
    end
    
    @confirmation = Confirmation.find_by(guest_id: @guest.id)
    if @confirmation
      status 420
      json({message: "Usuário já confirmou entrada!"})
    else
      @confirmation = Confirmation.create(guest_id: @guest.id)
      status 200
      json({message: "Entrada confirmada com sucesso!"})
    end
  else
    status 404
    json({message: "Usuário não encontrado!"})
  end
end

get '/guests/:id/edit' do
  @guest = Guest.find(params[:id])
  erb :guest
end

post '/guests/confirm/:salt' do
  @guest = Guest.find_by(salt: params[:salt])
  
  @confirmation = Confirmation.find_by(guest_id: @guest.id)
  if(@confirmation)
    @message = "O usuário já confirmou a entrada!"
    @message_type = "warning"
  else
    @confirmation = Confirmation.create(guest_id: @guest.id)
    @message = "Entrada confirmada com sucesso!"
    @message_type = "success"
  end
    
  erb :guest_show
end

post '/guest' do
  @guest = Guest.new(
    name: params[:name], 
    phone: params[:phone], 
    age: params[:age],
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

put '/guests/:id/disable' do
  @guest = Guest.find(params[:id])
  @guest.update(is_active: !@guest.is_active)
  {is_active: @guest.is_active}.to_json
end

get '/guests' do
  @guests = Guest.all
  erb :guests
end
