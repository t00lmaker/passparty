class Guest < ActiveRecord::Base
  has_one :confirmation

  validates :name, presence: true
  validates :phone, presence: true, length: { is: 15 }
  validates :is_active, inclusion: { in: [true, false] }
  validates :age, presence: true, inclusion: { in: ["idoso", "adulto", "adolescente", "crianca"] }
end