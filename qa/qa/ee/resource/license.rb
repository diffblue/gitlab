# frozen_string_literal: true

module QA
  module EE
    module Resource
      class License < QA::Resource::Base
        attr_accessor :license

        attributes :id,
          :plan,
          :starts_at,
          :expires_at,
          :historical_max,
          :maximum_user_count,
          :expired,
          :overage,
          :user_limit,
          :active_users,
          :licensee,
          :add_ons

        class << self
          def all(api_client = nil)
            instance(api_client).all
          end

          def delete_all(api_client = nil)
            instance(api_client).delete_all
          end

          private

          def instance(api_client)
            init { |resource| resource.api_client = api_client || QA::Runtime::API::Client.as_admin }
          end
        end

        def initialize
          @api_client = QA::Runtime::API::Client.as_admin
        end

        def fabricate!
          QA::Page::Main::Login.perform(&:sign_in_using_admin_credentials)
          QA::Page::Main::Menu.perform(&:go_to_admin_area)
          QA::Page::Main::Login.perform(&:set_up_new_admin_password_if_required)
          QA::Page::Admin::Menu.perform(&:click_subscription_menu_link)

          EE::Page::Admin::Settings::Component::AddLicense.perform do |admin_settings|
            if EE::Page::Admin::Subscription.perform(&:license?)
              QA::Runtime::Logger.warn("Environment already has a valid license, skipping!")
            else
              QA::Page::Admin::Menu.perform(&:go_to_general_settings)
              admin_settings.add_new_license(license)

              unless EE::Page::Admin::Subscription.perform(&:has_ultimate_subscription_plan?)
                raise "Adding license key was unsuccessful.\n#{license_info}"
              end

              QA::Runtime::Logger.info("Successfully added license key. Details:\n#{license_info}")
            end
          end

          QA::Page::Main::Menu.perform(&:sign_out_if_signed_in)
        end

        def fabricate_via_api!
          api_get
        rescue NoValueError
          # This is not technically correct because we are not able to determine license details
          # from license contents but we generally only need one license in the environment
          #
          # This is similar behaviour to UI fabrication where we only check general presence of a license
          begin
            existing_license_id = all
              .find { |license| !license[:expired] }
              &.fetch(:id)

            if existing_license_id
              QA::Runtime::Logger.warn("Environment already has a valid license, skipping!")
              self.id = existing_license_id
              return api_get
            end

            api_post.tap { QA::Runtime::Logger.info("Successfully added license key. Details:\n#{license_info}") }
          rescue RuntimeError => e
            unless e.message.include?('Your password expired')
              QA::Runtime::Logger.error("Following license fabrication failed: #{base_license_info}")
              raise(e)
            end

            QA::Runtime::Logger.warn('Admin password must be reset before the default access token can be used. ' \
                                     'Setting password now...')

            QA::Page::Main::Login.perform(&:sign_in_using_admin_credentials)
            QA::Page::Main::Login.perform(&:set_up_new_admin_password_if_required)

            retry
          end
        end

        def api_post_path
          "/license"
        end

        def api_get_path
          "#{api_post_path}/#{id}"
        end

        def api_delete_path
          api_get_path
        end

        def api_post_body
          { license: license }
        end

        # All licenses in the instance
        #
        # @return [Array]
        def all
          auto_paginated_response(request_url("/licenses", per_page: "100"))
        end

        # Delete all licenses in the instance
        #
        # @return [void]
        def delete_all
          raise 'Unable to delete license on live environment' if QA::Specs::Helpers::ContextSelector.dot_com?

          errors = []

          QA::Runtime::Logger.info("Removing all licenses from instance!")
          all.each do |license|
            License.init do |resource|
              resource.id = license[:id]
              resource.api_client = api_client
            end.remove_via_api!
          rescue ResourceNotDeletedError => e
            errors << e.message
          end

          raise(ResourceNotDeletedError, "One or more licenses failed to delete: #{errors}") unless errors.empty?
        end

        private

        # License key length
        #
        # @return [Integer]
        def license_length
          license.to_s.strip.length
        end

        # Base info
        #
        # @return [Hash]
        def base_license_info
          @base_license_info ||= {
            test_license_mode: ENV['GITLAB_LICENSE_MODE'] == 'test',
            license_key_length: license_length,
            last_five_characters: license.to_s.strip[-5..]
          }
        end

        # License info
        #
        # @return [Hash]
        def license_info
          return base_license_info unless api_resource

          base_license_info.merge(api_resource.slice(:plan, :starts_at, :user_limit))
        end
      end
    end
  end
end
