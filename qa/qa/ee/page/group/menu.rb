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
              include SubMenus::SuperSidebar::Main
              include SubMenus::SuperSidebar::Secure
              include SubMenus::SuperSidebar::Plan
              include SubMenus::SuperSidebar::Analyze
              include SubMenus::SuperSidebar::Settings
            end
          end
        end
      end
    end
  end
end
