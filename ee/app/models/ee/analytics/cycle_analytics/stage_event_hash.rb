# frozen_string_literal: true

module EE
  module Analytics
    module CycleAnalytics
      module StageEventHash
        extend ActiveSupport::Concern

        prepended do
          has_many :cycle_analytics_group_stages, class_name: 'Analytics::CycleAnalytics::Stage', inverse_of: :stage_event_hash
        end

        class_methods do
          def unused_hashes_for(id)
            exists_query = ::Analytics::CycleAnalytics::Stage.where(stage_event_hash_id: id).select('1').limit(1)
            super.where.not('EXISTS (?)', exists_query)
          end
        end
      end
    end
  end
end
