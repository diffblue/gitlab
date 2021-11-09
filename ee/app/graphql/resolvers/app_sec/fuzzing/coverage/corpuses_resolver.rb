# frozen_string_literal: true

module Resolvers
  module AppSec
    module Fuzzing
      module Coverage
        class CorpusesResolver < BaseResolver
          type Types::AppSec::Fuzzing::Coverage::CorpusType, null: true

          alias_method :project, :object

          def resolve
            ::AppSec::Fuzzing::Coverage::CorpusesFinder.new(
              project: project
            ).execute
          end
        end
      end
    end
  end
end
