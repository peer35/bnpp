class AddUserEmailToRecords < ActiveRecord::Migration[5.0]
  def change
    add_column :records, :user_email, :string
  end
end
