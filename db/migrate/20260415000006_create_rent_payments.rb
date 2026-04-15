class CreateRentPayments < ActiveRecord::Migration[7.1]
  def change
    create_table :rent_payments do |t|
      t.references :property_lease, null: false, foreign_key: true, column: :lease_id
      t.references :tenant,         null: false, foreign_key: { to_table: :users }

      t.decimal :amount,          precision: 10, scale: 2, null: false
      t.decimal :expense_amount,  precision: 10, scale: 2, default: 0
      t.string  :status,          null: false, default: 'pending' # pending | paid | late | disputed
      t.date    :due_date,        null: false   # Date d'échéance (ex: 1er du mois)
      t.date    :paid_at                         # Date de paiement effectif
      t.string  :payment_method                  # virement | prelevement | cheque | especes
      t.jsonb   :data,            default: '{}'  # référence virement, notes, etc.

      t.timestamps
    end

    add_index :rent_payments, [:lease_id, :due_date], unique: true
    add_index :rent_payments, [:tenant_id, :status]
    add_index :rent_payments, :due_date
  end
end
