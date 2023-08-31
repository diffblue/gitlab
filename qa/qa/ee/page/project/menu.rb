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
              prepend SubMenus::Secure
              prepend SubMenus::Code
              prepend SubMenus::Analyze
            end
          end
        end
      end
    end
  end
end
