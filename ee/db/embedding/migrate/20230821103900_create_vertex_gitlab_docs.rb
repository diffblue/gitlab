# frozen_string_literal: true

class CreateVertexGitlabDocs < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    create_table :vertex_gitlab_docs do |t|
      t.timestamps_with_timezone null: false
      t.integer :version, default: 0, null: false
      t.vector :embedding, limit: 768
      t.text :url, null: false, limit: 2048
      t.text :content, null: false, limit: 32768
      t.jsonb :metadata, null: false
    end
  end

  def down
    drop_table :vertex_gitlab_docs
  end
end
