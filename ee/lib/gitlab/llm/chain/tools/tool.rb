# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        class Tool
          attr_reader :name, :description

          def initialize(name:, description:)
            @name = name
            @description = description
          end

          def execute(context, options)
            raise NotImplementedError
          end
        end
      end
    end
  end
end
