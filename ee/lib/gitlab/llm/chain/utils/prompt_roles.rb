# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Utils
        class PromptRoles
          def self.assistant(*inputs)
            join(:assistant, inputs)
          end

          def self.system(*inputs)
            join(:system, inputs)
          end

          def self.user(*inputs)
            join(:user, inputs)
          end

          def self.join(role, *inputs)
            [role, inputs.join("\n")]
          end
        end
      end
    end
  end
end
