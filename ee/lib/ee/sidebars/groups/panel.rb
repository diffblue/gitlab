# frozen_string_literal: true

module EE
  module Sidebars
    module Groups
      module Panel
        extend ::Gitlab::Utils::Override

        override :configure_menus
        def configure_menus
          super

          add_menu(::Sidebars::Groups::Menus::TrialExperimentMenu.new(context))
        end
      end
    end
  end
end
