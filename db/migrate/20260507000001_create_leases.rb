class CreateLeases < ActiveRecord::Migration[7.2]
  def change
    create_table :leases do |t|
      t.references :tenant, null: false, foreign_key: { to_table: :users }
      t.references :room,   null: false, foreign_key: true
      t.date       :start_date,       null: false
      t.date       :end_date
      t.decimal    :monthly_rent,     precision: 10, scale: 2, null: false
      t.decimal    :monthly_charges,  precision: 10, scale: 2, null: false, default: 0
      t.decimal    :deposit,          precision: 10, scale: 2, null: false, default: 0
      t.string     :status,           null: false, default: 'active'
      t.datetime   :signed_at
      t.timestamps
    end

    add_index :leases, :status
    add_index :leases, [:room_id, :status]
  end
end
