# frozen_string_literal: true

module EE
  module Terraform
    module States
      module DestroyService
        extend ::Gitlab::Utils::Override

        private

        override :process_batch
        def process_batch(batch)
          deleted_params = batch.map { |version| version.replicator.deleted_params }

          super

          ::Terraform::StateVersion.replicator_class.bulk_create_delete_events_async(deleted_params)
        end
      end
    end
  end
end
