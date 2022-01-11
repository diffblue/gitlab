# frozen_string_literal: true

module QA
  module EE
    module Resource
      class License < QA::Resource::Base
        def fabricate!(license)
          QA::Page::Main::Login.perform(&:sign_in_using_admin_credentials)
          QA::Page::Main::Menu.perform(&:go_to_admin_area)
          QA::Page::Admin::Menu.perform(&:click_subscription_menu_link)

          EE::Page::Admin::License.perform do |license_page|
            unless license_page.license?
              QA::Page::Admin::Menu.perform(&:go_to_general_settings)

              license_page.add_new_license(license)
            end
          end

          QA::Page::Main::Menu.perform(&:sign_out_if_signed_in)
        end
      end
    end
  end
end
