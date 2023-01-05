# frozen_string_literal: true

module EE
  module SystemCheck
    module RakeTask
      module AppTask
        extend ActiveSupport::Concern

        class_methods do
          extend ::Gitlab::Utils::Override

          override :checks
          def checks
            super + [
              ::SystemCheck::App::SearchCheck,
              ::SystemCheck::App::AdvancedSearchMigrationsCheck
            ]
          end
        end
      end
    end
  end
end
