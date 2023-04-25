# frozen_string_literal: true

FactoryBot.define do
  factory :tanuki_bot_mvc, class: 'Embedding::TanukiBotMvc' do
    url { 'http://example.com/path/to/a/doc' }

    metadata do
      {
        info: 'A description',
        source: 'path/to/a/doc.md',
        source_type: 'doc'
      }
    end

    content { 'Some text' }
    embedding { Array.new(1536, 0.3) }
  end
end
