class CreateRooms < ActiveRecord::Migration[7.2]
  def change
    create_table :rooms do |t|
      t.string     :name,         null: false
      t.decimal    :surface_area, precision: 8,  scale: 2
      t.decimal    :rent,         precision: 10, scale: 2, null: false
      t.decimal    :charges,      precision: 10, scale: 2, null: false, default: 0
      t.references :property,     null: false, foreign_key: true
      t.timestamps
    end
  end
end
