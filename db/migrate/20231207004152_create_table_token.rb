class CreateTableToken < ActiveRecord::Migration[7.1]
  create_table :tokens do |t|
    t.string :value, index: true
    t.belongs_to :user, index: true
    t.timestamps
  end
end
