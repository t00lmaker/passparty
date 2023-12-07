class CreateTableToken < ActiveRecord::Migration[7.1]
  create_table :tokens do |t|
    t.string :value
    t.timestamps
  end
end
