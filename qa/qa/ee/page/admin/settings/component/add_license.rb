# frozen_string_literal: true

module QA
  module EE
    module Page
      module Admin
        module Settings
          module Component
            class AddLicense < QA::Page::Base
              view 'ee/app/views/admin/application_settings/_add_license.html.haml' do
                element 'expand-add-license-button'
                element 'accept-eula-checkbox-label'
                element 'license-key-field'
                element 'license-type-key-radio-label'
                element 'license-upload-button'
              end

              def add_new_license(key)
                raise 'License key empty!' if key.to_s.strip.empty?

                click_element('expand-add-license-button')
                click_element('license-type-key-radio-label')
                fill_element('license-key-field', key.strip)
                click_element('accept-eula-checkbox-label')
                click_element('license-upload-button')
              end
            end
          end
        end
      end
    end
  end
end
