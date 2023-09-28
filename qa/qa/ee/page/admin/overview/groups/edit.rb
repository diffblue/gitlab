# frozen_string_literal: true

module QA
  module EE
    module Page
      module Admin
        module Overview
          module Groups
            module Edit
              extend QA::Page::PageConcern

              def self.included(base)
                super

                base.class_eval do
                  view 'ee/app/views/admin/_namespace_plan.html.haml' do
                    element 'plan-dropdown'
                  end
                end
              end

              def select_plan(plan)
                select_element('plan-dropdown', plan)
              end
            end
          end
        end
      end
    end
  end
end
