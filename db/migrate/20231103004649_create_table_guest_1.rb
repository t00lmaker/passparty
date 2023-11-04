class CreateTableGuest1 < ActiveRecord::Migration[7.1]
  def change
    create_table :guest do |t|
      t.string :name
      t.string :email
      t.string :phone
      t.boolean :has_children
      # other columns...
    end
  end
end
