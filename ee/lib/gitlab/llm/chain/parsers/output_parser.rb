# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Parsers
        class OutputParser
          attr_reader :output

          def initialize(output:)
            @output = output
          end

          def parse
            raise NotImplementedError
          end
        end
      end
    end
  end
end
