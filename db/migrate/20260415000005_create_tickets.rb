class CreateTickets < ActiveRecord::Migration[7.1]
  def change
    create_table :tickets do |t|
      t.references :property,    null: false, foreign_key: true
      t.references :tenant,      null: false, foreign_key: { to_table: :users }
      t.references :assigned_to, foreign_key: { to_table: :users }

      t.string  :category,    null: false  # plomberie | electricite | chauffage | serrurerie | autre
      t.text    :description, null: false
      t.string  :status,      null: false, default: 'open'   # open | assigned | resolved | closed
      t.string  :priority,    null: false, default: 'normal' # normal | urgent
      t.jsonb   :data,        default: '{}'                  # photos URLs, notes internes
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :tickets, [:property_id, :status]
    add_index :tickets, [:tenant_id, :status]
  end
end
