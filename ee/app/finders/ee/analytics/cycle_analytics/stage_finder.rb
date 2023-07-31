# frozen_string_literal: true

module EE
  module Analytics
    module CycleAnalytics
      module StageFinder
        extend ::Gitlab::Utils::Override

        NUMBERS_ONLY = /\A\d+\z/

        def initialize(parent:, stage_id:)
          @parent = parent
          @stage_id = stage_id
        end

        override :execute
        def execute
          return super if in_memory_default_stage?

          raise(::Gitlab::Access::AccessDeniedError) unless persisted_stages_available?

          parent.cycle_analytics_stages.find(stage_id)
        end

        private

        attr_reader :parent, :stage_id

        def in_memory_default_stage?
          !NUMBERS_ONLY.match?(stage_id.to_s)
        end

        def persisted_stages_available?
          ::Gitlab::Analytics::CycleAnalytics.licensed?(parent)
        end
      end
    end
  end
end
