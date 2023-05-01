# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module SubMenus
          module SuperSidebar
            module Secure
              extend QA::Page::PageConcern

              def self.prepended(base)
                super

                base.class_eval do
                  prepend Page::SubMenus::SuperSidebar::Secure
                end
              end

              def go_to_license_compliance
                open_secure_submenu('License compliance')
              end
            end
          end
        end
      end
    end
  end
end
