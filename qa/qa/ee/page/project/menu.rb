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
              prepend SubMenus::LicenseCompliance
              prepend SubMenus::SecurityCompliance
              prepend SubMenus::Analytics
              prepend SubMenus::Repository
              prepend SubMenus::Settings

              if QA::Runtime::Env.super_sidebar_enabled?
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
end
