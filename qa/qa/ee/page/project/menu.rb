# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Menu
          extend QA::Page::PageConcern

          def self.prepended(base)
            super

            base.class_eval do
              prepend SubMenus::SuperSidebar::Secure
              prepend SubMenus::SuperSidebar::Code
              prepend SubMenus::SuperSidebar::Analyze
            end
          end
        end
      end
    end
  end
end
