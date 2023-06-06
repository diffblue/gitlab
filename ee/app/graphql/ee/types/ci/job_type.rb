# frozen_string_literal: true

module EE
  module Types
    module Ci
      module JobType
        extend ActiveSupport::Concern

        prepended do
          field :ai_failure_analysis,
            GraphQL::Types::String,
            null: true,
            description: 'Ai generated analysis of the root cause of failure.',
            alpha: { milestone: '16.1' },
            authorize: :read_build_trace,
            calls_gitaly: true
        end

        def ai_failure_analysis
          Ai::JobFailureAnalysis.new(object).content
        end
      end
    end
  end
end
