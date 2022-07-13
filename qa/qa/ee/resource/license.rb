# frozen_string_literal: true

module QA
  module EE
    module Resource
      class License < QA::Resource::Base
        attribute :id
        attribute :plan
        attribute :licensee

        def fabricate!(license)
          QA::Page::Main::Login.perform(&:sign_in_using_admin_credentials)
          QA::Page::Main::Menu.perform(&:go_to_admin_area)
          QA::Page::Admin::Menu.perform(&:click_subscription_menu_link)

          EE::Page::Admin::Settings::Component::AddLicense.perform do |admin_settings|
            if EE::Page::Admin::Subscription.perform(&:license?)
              QA::Runtime::Logger.debug("A license already exists.")
            else
              QA::Page::Admin::Menu.perform(&:go_to_general_settings)

              admin_settings.add_new_license(license)

              license_length = license.to_s.strip.length
              license_info = "TEST_LICENSE_MODE: #{ENV['TEST_LICENSE_MODE']}. License key length: #{license_length}. " + (license_length > 5 ? "Last five characters: #{license.to_s.strip[-5..]}" : "")

              if EE::Page::Admin::Subscription.perform(&:has_ultimate_subscription_plan?)
                QA::Runtime::Logger.debug("Successfully added license key. #{license_info}")
              else
                raise "Adding license key was unsuccessful. #{license_info}"
              end
            end
          end

          QA::Page::Main::Menu.perform(&:sign_out_if_signed_in)
        end

        def self.delete_all
          result = true

          all.each do |license|
            Resource::License.init do |resource|
              response = resource.delete(QA::Runtime::API::Request.new(QA::Runtime::API::Client.as_admin,
                                                                   "/license/#{license[:id]}").url)

              if response.code != 204
                QA::Runtime::Logger.warn("Failed to remove license #{license[:id]}.")
                result = false
              end
            end
          end

          raise ResourceNotDeletedError unless result
        end

        # Get all licenses from the API
        #
        # @param [Integer] per_page numbers of license per page
        # @return [Array<Hash>] parsed response body
        def self.all(per_page: 100)
          response = nil
          Resource::License.init do |license|
            response = license.get(QA::Runtime::API::Request.new(QA::Runtime::API::Client.as_admin,
                                                          '/licenses',
                                                          per_page: per_page.to_s).url)
            raise ResourceQueryError unless response.code == 200
          end.parse_body(response)
        end
      end
    end
  end
end
