class AddIndexToGuestsSalt < ActiveRecord::Migration[7.1]
  def change
    add_index :guests, :salt
  end
end
