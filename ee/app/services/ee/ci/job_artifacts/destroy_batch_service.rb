# frozen_string_literal: true

module EE
  module Ci
    module JobArtifacts
      module DestroyBatchService
        extend ::Gitlab::Utils::Override

        private

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

          insert_geo_event_records(artifacts)
        end

        def insert_geo_event_records(artifacts)
          ::Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification.allow_cross_database_modification_within_transaction(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/351849') do
            ::Geo::JobArtifactDeletedEventStore.bulk_create(artifacts)
          end
        end
      end
    end
  end
end
