# frozen_string_literal: true

module QA
  module EE
    module Page
      module Admin
        module Settings
          module Component
            class AddLicense < QA::Page::Base
              view 'ee/app/views/admin/application_settings/_add_license.html.haml' do
                element :expand_add_license_button
                element :accept_eula_checkbox
                element :license_key_field
                element :license_type_key_radio
                element :license_upload_button
              end

              def add_new_license(key)
                raise 'License key empty!' if key.to_s.strip.empty?

                click_element(:expand_add_license_button)
                choose_element(:license_type_key_radio, true)
                fill_element(:license_key_field, key.strip)
                check_element(:accept_eula_checkbox)
                click_element(:license_upload_button)
              end
            end
          end
        end
      end
    end
  end
end
