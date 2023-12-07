require 'bcrypt'
require 'jwt'

class User < ActiveRecord::Base
  has_one :token


  def self.get_from_token(token)
    token = Token.find_by(value: token)
    puts "from token: #{token}"
    if token
      puts "2 from token: #{token.user}"
      return token.user
    else
      return nil
    end
  end

  def self.authenticate(login, pass)
    puts "#0 #{login} e #{pass}"
    user = User.find_by(email: login)
    unless(user)
      user = User.find_by(username: login)
    end
    puts "#1 #{user} "
    if(user)

      # BCrypt::Engine.generate_salt
      # BCrypt::Engine.hash_secret 'naul1991', salt
      digest = BCrypt::Engine.hash_secret pass, user.salt 
      
      puts "#2 #{digest}"
      puts "#3 #{user.password_digest}"
      if( digest == user.password_digest )
        hmac_secret = ENV['SECRET'] || 'batat8$AoVenc3d0r'
        payload = { user_id: user.id }
        token = Token.create(value: JWT.encode(payload, hmac_secret, 'HS256'), user: user)
        token.save
        token.value
      else
        puts "#5"
        nil
      end 
    end
  end

end