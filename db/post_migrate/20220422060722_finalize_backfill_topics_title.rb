# frozen_string_literal: true

class FinalizeBackfillTopicsTitle < Gitlab::Database::Migration[1.0]
  MIGRATION = 'BackfillTopicsTitle'

  def up
    finalize_background_migration(MIGRATION)
  end

  def down
    # no-op
  end
end
