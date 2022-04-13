# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountImportedProjectsMetric < DatabaseMetric
          operation :count

          def initialize(time_frame:, options: {})
            super

            raise ArgumentError, "import_type options attribute is required" unless import_type.present?
          end

          relation { ::Project }

          private

          def start
            start = time_constraints[:created_at].first

            ::Project
              .select(:id)
              .where(Project.arel_table[:created_at].gteq(start)) # rubocop:disable UsageData/LargeTable
              .order(created_at: :asc).limit(1).first&.id
          end

          def finish
            finish = time_constraints[:created_at].last

            ::Project
              .select(:id)
              .where(Project.arel_table[:created_at].lteq(finish)) # rubocop:disable UsageData/LargeTable
              .order(created_at: :desc).limit(1).first&.id
          end

          def relation
            super.imported_from(import_type) # rubocop: disable CodeReuse/ActiveRecord
          end

          def import_type
            options[:import_type]
          end
        end
      end
    end
  end
end
