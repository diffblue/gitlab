# frozen_string_literal: true

module QA
  module EE
    module Runtime
      module Path
        class << self
          def fixtures_path
            File.expand_path('../fixtures', __dir__)
          end

          def fixture(*args)
            ::File.join(fixtures_path, *args)
          end
        end
      end
    end
  end
end
