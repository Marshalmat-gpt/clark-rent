class CreateLeaseApplications < ActiveRecord::Migration[7.1]
  def change
    create_table :lease_applications do |t|
      t.references :property_lease, null: false, foreign_key: true, column: :lease_id
      t.references :applicant,      null: false, foreign_key: { to_table: :users }
      t.string  :status,            null: false, default: 'new'
      t.text    :description
      t.jsonb   :data,              default: '{}'
      t.timestamps
    end
    add_index :lease_applications, [:lease_id, :status]
    add_index :lease_applications, [:applicant_id, :status]
  end
end
