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
require 'tzinfo'

configure do
  I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
  I18n.load_path = Dir[File.join(settings.root, 'locales', '*.yml')]
  I18n.backend.load_translations

  ENV['TZ'] = 'America/Sao_Paulo' 
end

OTR::ActiveRecord.configure_from_file! "config/database.yml"
OTR::ActiveRecord.establish_connection!

URL = ENV["APP_URL"] || "localhost:9292" 

#not_found do
#  erb :not_found
#end

#error 500 do
#  erb :internal_error
#end


get '/' do
  @guest = Guest.new
  erb :index
end

get '/guest' do
  @guest = Guest.new
  erb :guest_form_new
end

get '/guests/import' do
  erb :guests_import
end

get '/guests/export' do
  content_type 'application/csv'
  attachment "convidados.csv"

  CSV.generate do |csv|
    csv << ["id", "Convidado", "Faixa Etária", "Telefone", "Ativo"]
    Guest.all.each do |guest|
      csv << [guest.id, guest.name, guest.age, guest.phone, guest.is_active ? 'SIM' : 'NÃO' ]
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
    @message = "Usuário não encontrado ou já confirmado!"
    @message_type = "warning"
    erb :not_found
  end
end

get '/guests/:id' do
  @guest = Guest.find(params[:id])
  qrcode = RQRCode::QRCode.new("#{@guest[:salt]}")
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
  content_type :json

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
      @confirmation = Confirmation.create(guest_id: @guest.id, details_confirm:  Time.now.strftime("%H:%M do dia %d/%m/%Y"))
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
  erb :guest_form_edit
end

put '/guests/:id' do
  @guest = Guest.find(params[:id])
  if @guest.nil?
    @message = "Convidado não enconrado!"
    @message_type = "warning"
    redirect '/guests'
  else
    if @guest.update(
      name: params[:name], 
      phone: params[:phone],
      age: params[:age]
    )
      @message = "Entrada confirmada com sucesso!"
      @message_type = "success"
    else
      @message = "Convidado não pode ser alterado, contact o administrador."
      @message_type = "warning"
    end
    erb :guest_show
  end
end

post '/guests/confirm/:salt' do
  @guest = Guest.find_by(salt: params[:salt])
  
  @confirmation = Confirmation.find_by(guest_id: @guest.id)
  if(@confirmation)
    @message = "O usuário já confirmou a entrada!"
    @message_type = "warning"
  else
    @confirmation = Confirmation.create(guest_id: @guest.id, details_confirm:  Time.now.strftime("%H:%M do dia %d/%m/%Y"))
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
  
  valid_guests = []
  invalid_guests = []
  
  if params[:file] && params[:file][:tempfile]
    i = 0
    CSV.foreach(params[:file][:tempfile], headers: true) do |row|
      i += 1
      from_to_attributes = {
        'id' => 'id',
        'Convidado' => 'name',
        'Faixa Etária' => 'age',
        'Telefone' => 'phone',
        'Ativo' => 'is_active'
      }
      row_hash = row.to_hash
      transformed_hash = row_hash.transform_keys { |key| from_to_attributes[key] }

      if transformed_hash.size != 5 or transformed_hash.values.any? {|v| v.nil? or v.empty?} 
        invalid_guests << {line: i, errors: "Dados incompletos ou inválidos. Check essa linha do arquivo!"}
        next
      end

      from_to_age = {
        "ADULTO" => "adulto",
        "ADULTA" => "adulto",
        "CRIANÇA" => "crianca",
        "IDOSO" => "idoso",
        "IDOSA" => "idoso",
        "ADOLESCENTE" => "adolescente",
        "Adulta/ Idosa" => "idoso"
      }

      transformed_hash['phone'] = transformed_hash['phone'].gsub(/\D/, '')
      transformed_hash['phone'] = transformed_hash['phone'].insert(0, '(').insert(3, ') ').insert(10, '-')
      transformed_hash['age'] = from_to_age[transformed_hash['age']] ? from_to_age[transformed_hash['age']] : "crianca"
      transformed_hash['is_active'] = transformed_hash['is_active'] == nil || transformed_hash['is_active'] == 'SIM' ? true : false
      
      guest = Guest.new(transformed_hash.merge({salt: SecureRandom.uuid.split("-")[0]}))
      if guest.valid?  
        valid_guests << guest        
      else 
        invalid_guests << {line: i, errors: guest.errors.full_messages.join(', ')}
      end
    end
  else
    @message = "Aquivo não encontrado!"
    @message_type = "danger"
    return erb :guests_import
  end

  if invalid_guests.empty?
    valid_guests.each do |guest|
      guest.save
    end
    @message = "Convidados salvos com suecesso! (Total #{valid_guests.size})"
    @message_type = "success"
    redirect '/guests'
  else
    @message = "Alguns problemas foram encontrados ao tentar salvar os convidados: "
    @message_type = "danger"
    @invalid_guests = invalid_guests
    erb :guests_import
  end
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
get '/confirmations' do
  @confirmations = Confirmation.all
  @confirmations.map { |c| puts c.guest }
  erb :confirmations
end

get '/confirmations/export' do
  content_type 'application/csv'
  attachment "presentes.csv"

  CSV.generate do |csv|
    csv << ["Convidado", "Telefone", "Confirmado em"]
    Confirmation.all.each do |confirmation|
      csv << [confirmation.guest.name, confirmation.guest.phone, confirmation.details_confirm]
    end
  end
end
