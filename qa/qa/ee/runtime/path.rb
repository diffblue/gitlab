# frozen_string_literal: true

module QA
  module EE
    module Runtime
      module Path
        def self.fixtures_path
          File.expand_path('../fixtures', __dir__)
        end
      end
    end
  end
end
