# frozen_string_literal: true

module QA
  module EE
    module Page
      module Admin
        module Settings
          module Component
            class Elasticsearch < QA::Page::Base
              view 'ee/app/views/admin/application_settings/_elasticsearch_form.html.haml' do
                element 'indexing-checkbox'
                element 'search-checkbox'
                element 'url-field'
                element 'submit-button'
                element 'expand-advanced-search-button'
              end

              def check_indexing
                check_element('indexing-checkbox', true)
              end

              def has_no_indexing_checkbox_element?
                has_no_element?('indexing-checkbox')
              end

              def check_search
                check_element('search-checkbox', true)
              end

              def enter_link(link)
                fill_element('url-field', link)
              end

              def click_submit
                click_element('submit-button')
              end

              def click_expand_advanced_search
                click_element('expand-advanced-search-button')
              end
            end
          end
        end
      end
    end
  end
end
