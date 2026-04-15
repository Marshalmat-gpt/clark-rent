class CreateProperties < ActiveRecord::Migration[7.1]
  def change
    create_table :properties do |t|
      t.references :owner,        null: false, foreign_key: { to_table: :users }
      t.string  :address,         null: false
      t.string  :zipcode,         null: false
      t.string  :city,            null: false
      t.integer :property_type,   null: false, default: 0
      t.boolean :furnished,       default: false
      t.float   :longitude
      t.float   :latitude
      t.float   :area,            default: 0.0
      t.integer :floor,           default: 0
      t.integer :building_floors, default: 1
      t.boolean :elevator,        default: false
      t.integer :parking,         default: 0
      t.string  :energy
      t.string  :ges
      t.date    :date_dpe
      t.string  :rent_type,       default: 'whole'
      t.integer :roommates
      t.jsonb   :data,            default: '{}'
      t.integer :stage,           default: 0
      t.timestamps
    end
    add_index :properties, [:owner_id, :city]
    add_index :properties, :city
  end
end
