class AlterTableAddDateConfirmation < ActiveRecord::Migration[7.1]
  def change
    add_column :confirmations, :details_confirm, :string
  end
end
