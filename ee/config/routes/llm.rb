# frozen_string_literal: true

namespace :llm do
  post 'tanuki_bot/ask' => 'tanuki_bot#ask', as: :tanuki_bot_ask, constraints: { format: :json }
end
