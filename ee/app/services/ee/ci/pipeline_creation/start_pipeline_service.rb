# frozen_string_literal: true

module EE
  module Ci
    module PipelineCreation
      module StartPipelineService
        extend ::Gitlab::Utils::Override

        override :execute
        def execute
          ::Ci::PipelineCreation::DropNotRunnableBuildsService.new(pipeline).execute
          ::Ci::PipelineCreation::DropSecretsProviderNotFoundBuildsService.new(pipeline).execute
          super
        end
      end
    end
  end
end
