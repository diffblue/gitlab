# frozen_string_literal: true

module Resolvers
  class SecurityTrainingUrlsResolver < BaseResolver
    type [::Types::Security::TrainingUrlType], null: true

    def resolve
      ::Security::TrainingUrlsFinder.new(object).execute
    end
  end
end
