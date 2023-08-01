# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Secure
          class DependencyList < QA::Page::Base
            view 'ee/app/assets/javascripts/dependencies/components/dependencies_table.vue' do
              element 'dependencies-table-content'
            end

            view 'ee/app/assets/javascripts/dependencies/components/app.vue' do
              element 'dependency-list-empty-state-description-content'
            end

            def has_dependency_count_of?(expected)
              within_element('dependencies-table-content') do
                # expected rows plus header row
                header_row = 1
                all('tr').count.equal?(expected + header_row)
              end
            end

            def has_empty_state_description?(text)
              within_element('dependency-list-empty-state-description-content') do
                has_text?(text)
              end
            end
          end
        end
      end
    end
  end
end
