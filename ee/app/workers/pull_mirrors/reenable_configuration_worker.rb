# frozen_string_literal: true

# Responsible for turning on pull mirror configurations
# after subscription's reactivation
module PullMirrors
  class ReenableConfigurationWorker
    include Gitlab::EventStore::Subscriber

    idempotent!
    data_consistency :sticky
    feature_category :source_code_management

    def handle_event(event)
      namespace = Namespace.find_by_id(event.data[:namespace_id])

      return if namespace.blank?

      cte = Gitlab::SQL::CTE.new(:namespace_ids, namespace.self_and_descendant_ids)

      Project
        .with(cte.to_arel) # rubocop:disable CodeReuse/ActiveRecord
        .joins('INNER JOIN namespace_ids ON namespace_ids.id = projects.namespace_id')  # rubocop:disable CodeReuse/ActiveRecord
        .each_batch(of: 100) do |batch|
        batch.with_hard_import_failures.each do |project|
          next unless project.mirror?

          project.import_state.reset_retry_count
          project.import_state.save!
        end
      end
    end
  end
end
