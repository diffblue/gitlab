# frozen_string_literal: true

module GitlabSubscriptions
  module AddOnPurchases
    module SelfManaged
      class ProvisionCodeSuggestionsService
        include ::Gitlab::Utils::StrongMemoize

        AddOnPurchaseSyncError = Class.new(StandardError)

        def execute
          result = license_has_code_suggestions? ? create_or_update_add_on_purchase : expire_prior_add_on_purchase

          unless result.success?
            raise AddOnPurchaseSyncError, "Error syncing subscription add-on purchases. Message: #{result[:message]}"
          end

          result
        rescue AddOnPurchaseSyncError => e
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)

          ServiceResponse.error(message: e.message)
        end

        private

        def license_has_code_suggestions?
          current_license&.online_cloud_license? && license_restrictions[:code_suggestions_seat_count].to_i > 0
        end

        def current_license
          License.current
        end
        strong_memoize_attr :current_license

        def license_restrictions
          current_license.license.restrictions
        end
        strong_memoize_attr :license_restrictions

        def empty_success_response
          ServiceResponse.success(payload: { add_on_purchase: nil })
        end

        def create_or_update_add_on_purchase
          service_class = if code_suggestions_add_on_purchase
                            GitlabSubscriptions::AddOnPurchases::UpdateService
                          else
                            GitlabSubscriptions::AddOnPurchases::CreateService
                          end

          service_class.new(namespace, code_suggestions_add_on, add_on_purchase_attributes).execute
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def code_suggestions_add_on_purchase
          GitlabSubscriptions::AddOnPurchase.active.find_by(namespace: namespace, add_on: code_suggestions_add_on)
        end
        strong_memoize_attr :code_suggestions_add_on_purchase
        # rubocop: enable CodeReuse/ActiveRecord

        def code_suggestions_add_on
          GitlabSubscriptions::AddOn.find_or_create_by_name(:code_suggestions)
        end
        strong_memoize_attr :code_suggestions_add_on

        def namespace
          nil
        end

        def add_on_purchase_attributes
          {
            quantity: license_restrictions[:code_suggestions_seat_count],
            expires_on: current_license.expires_at,
            purchase_xid: license_restrictions[:subscription_name]
          }
        end

        def expire_prior_add_on_purchase
          return empty_success_response unless code_suggestions_add_on_purchase

          GitlabSubscriptions::AddOnPurchases::SelfManaged::ExpireService.new(code_suggestions_add_on_purchase).execute
        end
      end
    end
  end
end
