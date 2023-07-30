# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Reconcile
      module Input
        # noinspection RubyLocalVariableNamingConvention - See https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/code-inspection/why-are-there-noinspection-comments/
        class ParamsExtractor
          include Messages

          # @param [Hash] value
          # @return [Hash]
          def self.extract(value)
            value => { original_params: Hash => original_params }

            original_params.symbolize_keys => {
              update_type: String => update_type,
              workspace_agent_infos: Array => workspace_agent_info_hashes_from_params,
            }

            # We extract the original string-keyed params, move them to the top level of the value hash with descriptive
            # names, and deep-symbolize keys. The original_params will still remain in the value hash as well for
            # debugging purposes.

            value.merge(
              {
                update_type: update_type,
                workspace_agent_info_hashes_from_params: workspace_agent_info_hashes_from_params
              }.deep_symbolize_keys.to_h
            )
          end
        end
      end
    end
  end
end
