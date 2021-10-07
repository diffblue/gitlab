# frozen_string_literal: true

class CreateIssueSearchTable < Gitlab::Database::Migration[1.0]
  def change
    create_table :issue_search_data, id: false do |t|
      t.references :issue, index: false, default: nil, primary_key: true, foreign_key: { on_delete: :cascade }, type: :bigint
      t.timestamps_with_timezone default: -> { 'CURRENT_TIMESTAMP' }
      t.tsvector :search_vector

      t.index :search_vector, using: :gin, name: 'index_issue_search_data_on_search_vector'
    end
  end
end
