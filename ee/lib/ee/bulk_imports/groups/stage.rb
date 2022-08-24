# frozen_string_literal: true

module EE
  module BulkImports
    module Groups
      module Stage
        extend ::Gitlab::Utils::Override

        private

        def ee_config
          @ee_config ||= {
            iterations: {
              pipeline: ::BulkImports::Groups::Pipelines::IterationsPipeline,
              maximum_source_version: '15.3.0',
              stage: 1
            },
            iterations_cadences: {
              pipeline: ::BulkImports::Groups::Pipelines::IterationsCadencesPipeline,
              minimum_source_version: '15.4.0',
              stage: 1
            },
            epics: {
              pipeline: ::BulkImports::Groups::Pipelines::EpicsPipeline,
              stage: 2
            },
            wiki: {
              pipeline: ::BulkImports::Common::Pipelines::WikiPipeline,
              stage: 2
            },
            # Override the CE stage value for the EntityFinisher Pipeline
            finisher: {
              stage: 4
            }
          }
        end

        override :config
        def config
          @config ||= super.deep_merge(ee_config)
        end
      end
    end
  end
end
