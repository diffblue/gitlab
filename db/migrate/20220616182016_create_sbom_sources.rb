# frozen_string_literal: true

class CreateSbomSources < Gitlab::Database::Migration[2.0]
  def change
    create_table :sbom_sources do |t|
      t.timestamps_with_timezone
      t.integer :source_type, null: false, limit: 2
      t.jsonb :source, null: false, default: {}
      t.text :fingerprint, null: false, limit: 255
    end
  end
end
