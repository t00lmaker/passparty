class CreateTableUser < ActiveRecord::Migration[7.1]
  create_table :users do |t|
    t.string :username
    t.string :email
    t.string :salt
    t.text :password_digest
    t.boolean :is_active
    t.timestamps
  end
end
