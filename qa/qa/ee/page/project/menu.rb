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
              prepend QA::Page::Project::SubMenus::Common
              prepend SubMenus::LicenseCompliance
              prepend SubMenus::SecurityCompliance
              prepend SubMenus::Analytics
              prepend SubMenus::Repository
              prepend SubMenus::Settings

              prepend SubMenus::SuperSidebar::SecurityCompliance if QA::Runtime::Env.super_sidebar_enabled?
            end
          end
        end
      end
    end
  end
end
