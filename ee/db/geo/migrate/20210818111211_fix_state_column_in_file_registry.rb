# frozen_string_literal: true

class FixStateColumnInFileRegistry < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  # The following cop is disabled because of https://gitlab.com/gitlab-org/gitlab/issues/33470
  # rubocop:disable Migration/UpdateColumnInBatches
  def up
    update_column_in_batches(:file_registry, :state, 2) do |table, query|
      query.where(table[:success].eq(true)) # rubocop:disable CodeReuse/ActiveRecord
    end
  end
  # rubocop:enable Migration/UpdateColumnInBatches

  def down
    # no-op
  end
end
