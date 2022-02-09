# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module BatchingStrategies
      # Batching class to use for destroying group member records that point to namespaces that don't exist.
      class InvalidGroupMembersBatchingStrategy < PrimaryKeyBatchingStrategy
        def apply_additional_filters(relation, job_arguments: [], job_class: nil)
          relation.where(member_namespace_id: nil).where(source_type: 'Group')
        end
      end
    end
  end
end
