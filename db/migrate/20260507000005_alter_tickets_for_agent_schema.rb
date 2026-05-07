class AlterTicketsForAgentSchema < ActiveRecord::Migration[7.2]
  def up
    drop_table :tickets

    create_table :tickets do |t|
      t.references :property,    null: false, foreign_key: true
      t.references :tenant,      null: false, foreign_key: { to_table: :users }
      t.references :assigned_to, null: true,  foreign_key: { to_table: :users }
      t.string  :category,    null: false, default: 'autre'
      t.text    :description, null: false
      t.string  :status,      null: false, default: 'open'
      t.string  :priority,    null: false, default: 'normal'
      t.jsonb   :data,                     default: '{}'
      t.datetime :resolved_at
      t.timestamps
    end

    add_index :tickets, %i[property_id status]
    add_index :tickets, %i[tenant_id status]
  end

  def down
    drop_table :tickets

    create_table :tickets do |t|
      t.references :reporter, null: false, foreign_key: { to_table: :users }
      t.references :room,     null: false, foreign_key: true
      t.string :title,       null: false
      t.text   :description
      t.string :status,   null: false, default: 'open'
      t.string :priority, null: false, default: 'normal'
      t.datetime :resolved_at
      t.timestamps
    end

    add_index :tickets, :status
    add_index :tickets, :priority
  end
end
