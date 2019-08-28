class AddNotitieToRecords < ActiveRecord::Migration[5.0]
  def change
    add_column :records, :notitie, :string
  end
end
