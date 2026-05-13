# Persists conversation history for a user's Clark agent session.
# Messages are stored as a JSONB array of { role:, content: } hashes,
# compatible with the Anthropic messages API format.
class ChatSession < ApplicationRecord
  MAX_TURNS = 20

  belongs_to :user

  # Appends one user message and one assistant reply, then trims history
  # to the last MAX_TURNS * 2 messages (i.e. MAX_TURNS full exchanges).
  def append_turn(user_message, assistant_reply)
    self.messages = (messages + [
      { 'role' => 'user',      'content' => user_message.to_s },
      { 'role' => 'assistant', 'content' => assistant_reply.to_s }
    ]).last(MAX_TURNS * 2)
  end

  # Returns the messages array formatted for Anthropic's messages API.
  def history
    messages
  end
end
