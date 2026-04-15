class CreatePropertyLeases < ActiveRecord::Migration[7.1]
  def change
    create_table :property_leases do |t|
      t.references :property,     null: false, foreign_key: true
      t.string  :name
      t.string  :status,          null: false, default: 'closed'
      t.decimal :amount,          precision: 10, scale: 2
      t.decimal :expense_amount,  precision: 10, scale: 2, default: 0
      t.date    :start_date
      t.date    :end_date
      t.decimal :irl_reference,   precision: 8, scale: 2
      t.jsonb   :data,            default: '{}'
      t.timestamps
    end
    add_index :property_leases, [:property_id, :status]
    add_index :property_leases, :status
    add_index :property_leases, :end_date
  end
end
