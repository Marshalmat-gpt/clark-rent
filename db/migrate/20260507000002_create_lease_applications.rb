class CreateLeaseApplications < ActiveRecord::Migration[7.2]
  def change
    create_table :lease_applications do |t|
      t.references :tenant, null: false, foreign_key: { to_table: :users }
      t.references :room,   null: false, foreign_key: true
      t.string     :status,        null: false, default: 'pending'
      t.text       :message
      t.datetime   :validated_at
      t.references :validated_by,  foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :lease_applications, :status
    add_index :lease_applications, [:tenant_id, :room_id], unique: true,
              name: 'index_lease_applications_on_tenant_and_room'
  end
end
