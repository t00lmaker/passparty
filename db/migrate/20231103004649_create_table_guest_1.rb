class CreateTableGuest1 < ActiveRecord::Migration[7.1]
  def change
    create_table :guests do |t|
      t.string :name
      t.string :phone
      t.string :salt
      t.string :age
      t.boolean :has_children
      t.boolean :is_active
      t.timestamps
    end
  end
end
