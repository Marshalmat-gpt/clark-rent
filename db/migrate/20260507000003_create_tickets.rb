class CreateTickets < ActiveRecord::Migration[7.2]
  def change
    create_table :tickets do |t|
      t.references :reporter, null: false, foreign_key: { to_table: :users }
      t.references :room,     null: false, foreign_key: true
      t.string     :title,       null: false
      t.text       :description
      t.string     :status,      null: false, default: 'open'
      t.string     :priority,    null: false, default: 'normal'
      t.datetime   :resolved_at
      t.timestamps
    end

    add_index :tickets, :status
    add_index :tickets, :priority
  end
end
