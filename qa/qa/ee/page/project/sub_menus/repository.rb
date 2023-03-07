# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module SubMenus
          module Repository
            extend QA::Page::PageConcern

            def self.prepended(base)
              base.class_eval do
                prepend QA::Page::Project::SubMenus::Common
              end
            end

            def go_to_repository_locked_files
              hover_repository do
                within_submenu do
                  click_element(:sidebar_menu_item_link, menu_item: 'Locked files')
                end
              end
            end
          end
        end
      end
    end
  end
end
