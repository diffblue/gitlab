# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module BatchingStrategies
      # Batching class to use for destroying group member records
      # that point to a namespace that doesn't exist.
      class InvalidGroupMembersBatchingStrategy < PrimaryKeyBatchingStrategy
        def apply_additional_filters(relation, job_arguments: [], job_class: nil)
          relation.where(source_type: 'Namespace')
        end
      end
    end
  end
end
