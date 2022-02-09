# frozen_string_literal: true

module AppSec
  module Fuzzing
    module Coverage
      class CorpusesFinder
        attr_reader :project

        def initialize(project:)
          @project = project
        end

        def execute
          AppSec::Fuzzing::Coverage::Corpus.by_project_id_and_status_hidden(project)
        end
      end
    end
  end
end
