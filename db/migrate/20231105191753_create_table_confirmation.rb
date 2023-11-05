class CreateTableConfirmation < ActiveRecord::Migration[7.1]
  def change
    create_table :confirmations do |t|
      t.belongs_to :guest, index: true
      t.text     :note
      t.timestamps
    end
  end
end
