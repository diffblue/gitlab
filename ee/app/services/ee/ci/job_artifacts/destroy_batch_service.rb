# frozen_string_literal: true

module EE
  module Ci
    module JobArtifacts
      module DestroyBatchService
        extend ::Gitlab::Utils::Override

        private

        override :destroy_related_records
        def destroy_related_records(artifacts)
          destroy_security_findings(artifacts)
        end

        override :after_batch_destroy_hook
        def after_batch_destroy_hook(artifacts)
          insert_geo_event_records(artifacts)
        end

        def destroy_security_findings(artifacts)
          job_ids = artifacts.map(&:job_id)

          ::Security::Finding.by_build_ids(job_ids).delete_all
        end

        def insert_geo_event_records(artifacts)
          ::Geo::JobArtifactDeletedEventStore.bulk_create(artifacts)
        end
      end
    end
  end
end
