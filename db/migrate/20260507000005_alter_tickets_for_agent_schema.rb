class AlterTicketsForAgentSchema < ActiveRecord::Migration[7.2]
  def change
    # Remove room-based schema
    remove_foreign_key :tickets, column: :reporter_id
    remove_foreign_key :tickets, column: :room_id
    remove_column :tickets, :reporter_id, :bigint
    remove_column :tickets, :room_id, :bigint
    remove_column :tickets, :title, :string

    # Add property/tenant schema required by ClarkAgent::ToolExecutor
    add_reference :tickets, :property, null: false, foreign_key: true
    add_reference :tickets, :tenant, null: false, foreign_key: { to_table: :users }
    add_reference :tickets, :assigned_to, null: true, foreign_key: { to_table: :users }
    add_column :tickets, :category, :string, null: false, default: 'autre'
    add_column :tickets, :data, :jsonb, default: '{}'

    # Align status values with agent expectations
    change_column_default :tickets, :status, from: 'open', to: 'open'

    add_index :tickets, %i[property_id status]
    add_index :tickets, %i[tenant_id status]
    remove_index :tickets, name: 'index_tickets_on_priority'
    remove_index :tickets, name: 'index_tickets_on_status'
  end
end
