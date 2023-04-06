# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module SubMenus
          module SuperSidebar
            module Secure
              extend QA::Page::PageConcern

              def self.prepended(base)
                super

                base.class_eval do
                  include Page::SubMenus::SuperSidebar::Secure
                end
              end

              def go_to_compliance_report
                open_secure_submenu('Compliance report')
              end
            end
          end
        end
      end
    end
  end
end
