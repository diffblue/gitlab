# frozen_string_literal: true

module EE
  module BulkImports
    module Projects
      module Stage
        extend ::Gitlab::Utils::Override

        private

        def ee_config
          @ee_config ||= {
            push_rule: {
              pipeline: ::BulkImports::Projects::Pipelines::PushRulePipeline,
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
