# frozen_string_literal: true

module EE
  module Ci
    module JobArtifacts
      module DestroyBatchService
        extend ::Gitlab::Utils::Override

        private

        override :destroy_around_hook
        def destroy_around_hook(artifacts)
          return yield unless ::Geo::EventStore.can_create_event?

          artifact_params = artifacts.map do |artifact|
            artifact.replicator.deleted_params
          end

          yield

          Sidekiq::Worker.skipping_transaction_check do
            ::Geo::JobArtifactReplicator.bulk_create_delete_events_async(artifact_params)
          end
        end

        override :after_batch_destroy_hook
        def after_batch_destroy_hook(artifacts)
          # This DestroyBatchService is used from different services.
          # One of them is when pipeline is destroyed, and then eventually call DestroyBatchService via DestroyAssociationsService.
          # So in this case even if it is invoked after a transaction but it is still under Ci::Pipeline.transaction.
          Sidekiq::Worker.skipping_transaction_check do
            ::Gitlab::EventStore.publish(
              ::Ci::JobArtifactsDeletedEvent.new(data: { job_ids: artifacts.map(&:job_id) })
            )
          end
        end
      end
    end
  end
end
