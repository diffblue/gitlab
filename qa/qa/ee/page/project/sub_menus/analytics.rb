# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module SubMenus
          module Analytics
            extend QA::Page::PageConcern

            def go_to_insights
              hover_analytics do
                within_submenu do
                  click_element(:sidebar_menu_item_link, menu_item: 'Insights')
                end
              end
            end

            def hover_analytics
              within_sidebar do
                find_element(:sidebar_menu_link, menu_item: 'Analytics').hover

                yield
              end
            end

            def go_to_value_stream_analytics
              hover_analytics do
                within_submenu do
                  click_element(:sidebar_menu_item_link, menu_item: 'Value stream')
                end
              end
            end

            def go_to_merge_request_analytics
              hover_analytics do
                within_submenu do
                  click_element(:sidebar_menu_item_link, menu_item: 'Merge request')
                end
              end
            end
          end
        end
      end
    end
  end
end
