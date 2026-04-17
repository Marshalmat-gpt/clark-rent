class CreateProperties < ActiveRecord::Migration[7.2]
  def change
    create_table :properties do |t|
      t.string     :name,    null: false
      t.string     :address, null: false
      t.references :user,    null: false, foreign_key: true
      t.timestamps
    end
  end
end
