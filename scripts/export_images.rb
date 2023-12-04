require 'rqrcode'
require 'rmagick'
require 'otr-activerecord'

require './models/guest'

class QRCodeGenerator
  def self.generate(guest)
    qrcode = RQRCode::QRCode.new(guest.salt)
    qr_png = qrcode.as_png(size: 800)

    qr_image = Magick::Image.from_blob(qr_png.to_s).first

    logo = Magick::Image.read("/home/luan/Workspace/passparty/scripts/logo-horizontal.png").first
    #logo.resize_to_fit!(200, 200) # resize logo if needed

    name_image = Magick::Image.new(300, 300) # create a new image for the name
    draw = Magick::Draw.new
    draw.annotate(name_image, 0, 0, 70, 30, guest.name) { # draw the name on the new image
      pointsize= 104
      fill = 'black'
      gravity = Magick::CenterGravity
    }

    result = Magick::Image.new(800, 1100) # create a new image to hold all elements
    result.composite!(name_image, Magick::NorthGravity, Magick::OverCompositeOp) # composite the name image onto the new image
    result.composite!(qr_image, Magick::CenterGravity, Magick::OverCompositeOp) # composite the QR code image onto the new image
    result.composite!(logo, Magick::SouthGravity, Magick::OverCompositeOp) # composite the logo image onto the new image

    result.write("/home/luan/Workspace/passparty/scripts/images/#{guest.id}.png")
  end
end

OTR::ActiveRecord.configure_from_file! "config/database.yml"
OTR::ActiveRecord.establish_connection!

@guests = Guest.first(100)
for guest in @guests
  QRCodeGenerator.generate(guest)
end