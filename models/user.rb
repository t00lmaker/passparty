require 'bcrypt'
require 'jwt'

class User < ActiveRecord::Base
  has_one :token


  def self.get_from_token(token)
    token = Token.find_by(value: token)
    token.user if token
  end

  def self.authenticate(login, pass)
    user = User.find_by(email: login)
    unless(user)
      user = User.find_by(username: login)
    end
    if(user)
      hmac_secret = ENV['SECRET'] || 'batat8$AoVenc3d0r'
      digest = BCrypt::Password.create(pass + user.salt) 
      if( digest == user.password_digest )
        payload = { user_id: user.id }
        token = Token.create(value: JWT.encode(payload, hmac_secret, 'HS256'))
        token.save
        token.value
      else
        nil
      end 
    end
  end

end