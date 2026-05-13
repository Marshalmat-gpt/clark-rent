class CreateChatSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :chat_sessions do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.jsonb :messages, null: false, default: []
      t.timestamps
    end
  end
end
