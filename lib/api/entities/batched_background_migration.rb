# frozen_string_literal: true

module API
  module Entities
    class BatchedBackgroundMigration < Grape::Entity
      expose :id
      expose :job_class_name
      expose :table_name
      expose :status do |background_migration|
        background_migration.status_name
      end
      expose :created_at
    end
  end
end
