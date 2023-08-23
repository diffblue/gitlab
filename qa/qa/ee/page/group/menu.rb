# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Menu
          extend QA::Page::PageConcern

          def self.prepended(base)
            super

            base.class_eval do
              include SubMenus::Main
              include SubMenus::Secure
              include SubMenus::Plan
              include SubMenus::Analyze
              include SubMenus::Settings
            end
          end
        end
      end
    end
  end
end
