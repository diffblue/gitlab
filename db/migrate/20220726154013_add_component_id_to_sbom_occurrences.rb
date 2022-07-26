# frozen_string_literal: true

class AddComponentIdToSbomOccurrences < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    # Code using this table has not been implemented yet, so it should be empty.
    add_column :sbom_occurrences, :component_id, :bigint, null: false  # rubocop:disable Rails/NotNullColumn
  end

  def down
    remove_column :sbom_occurrences, :component_id
  end
end
