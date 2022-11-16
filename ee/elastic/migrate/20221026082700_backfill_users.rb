# frozen_string_literal: true

class BackfillUsers < Elastic::Migration
  include Elastic::MigrationHelper

  BATCH_SIZE = 1000
  ITERATIONS_PER_RUN = 10
  throttle_delay 1.minute
  batched!
  retry_on_failure

  def migrate
    last_id = max_processed_id || 0
    log "Indexing users starting from id = #{last_id}"

    User.where("id > ?", last_id).each_batch(of: BATCH_SIZE) do |users, index| # rubocop:disable CodeReuse/ActiveRecord(RuboCop)
      last_id = users.last.id
      log "Executing iteration #{index} with last user id: #{last_id}"

      Elastic::ProcessInitialBookkeepingService.track!(*users)

      next if index < ITERATIONS_PER_RUN

      break
    end

    set_migration_state(max_processed_id: last_id)
  end

  def completed?
    maximum_user_id = User.maximum(:id)
    log "Migration completed? max_processed_id(#{max_processed_id}); maximum_user_id(#{maximum_user_id})"

    max_processed_id && max_processed_id >= maximum_user_id
  end

  def document_type
    :user
  end

  private

  def max_processed_id
    migration_state[:max_processed_id]
  end
end
