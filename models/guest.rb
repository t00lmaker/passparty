class Guest < ActiveRecord::Base
  has_one :confirmation

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true, length: { is: 11 }
  validates :has_children, inclusion: { in: [true, false] }
  validates :is_active, inclusion: { in: [true, false] }
end