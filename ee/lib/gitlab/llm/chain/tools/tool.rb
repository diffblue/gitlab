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
        end
      end
    end
  end
end
