# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module SubMenus
          module Analyze
            extend QA::Page::PageConcern

            def self.included(base)
              super

              base.class_eval do
                include Page::SubMenus::Analyze
              end
            end

            def go_to_contribution_analytics
              open_analyze_submenu('Contribution analytics')
            end

            def go_to_devops_adoption
              open_analyze_submenu('DevOps adoption')
            end

            def go_to_productivity_analytics
              open_analyze_submenu('Productivity analytics')
            end
          end
        end
      end
    end
  end
end
