# frozen_string_literal: true

module Types
  module AppSec
    module Fuzzing
      module Coverage
        class CorpusType < BaseObject
          graphql_name 'CoverageFuzzingCorpus'
          description 'Corpus for a coverage fuzzing job.'

          authorize :read_coverage_fuzzing

          field :id, ::Types::GlobalIDType[::AppSec::Fuzzing::Coverage::Corpus],
            null: false, description: 'ID of the corpus.'

          field :package, ::Types::Packages::PackageDetailsType,
            null: false, description: 'Package of the corpus.'
        end
      end
    end
  end
end
