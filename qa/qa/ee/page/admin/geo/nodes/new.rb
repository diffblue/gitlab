# frozen_string_literal: true

module QA
  module EE
    module Page
      module Admin
        module Geo
          module Nodes
            class New < QA::Page::Base
              view 'ee/app/assets/javascripts/geo_site_form/components/geo_site_form_core.vue' do
                element :site_name_field
                element :site_url_field
              end

              view 'ee/app/assets/javascripts/geo_site_form/components/geo_site_form.vue' do
                element :add_site_button
              end

              def set_site_name(name)
                fill_element :site_name_field, name
              end

              def set_site_address(address)
                fill_element :site_url_field, address
              end

              def add_site!
                click_element :add_site_button
              end
            end
          end
        end
      end
    end
  end
end
