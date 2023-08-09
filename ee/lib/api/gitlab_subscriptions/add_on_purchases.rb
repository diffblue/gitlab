# frozen_string_literal: true

module API
  module GitlabSubscriptions
    class AddOnPurchases < ::API::Base
      feature_category :purchase
      urgency :low

      before do
        authenticated_as_admin!

        not_found!('REST API endpoint not found') unless Feature.enabled?(:purchase_code_suggestions)

        @namespace = find_namespace!(params[:id])
        @add_on = find_or_create_subscription_add_on!(params[:add_on_name])
      end

      resource :namespaces, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Create an add-on purchase for the namespace' do
          detail 'Creates a subscription add-on record for the given namespaces and add-on'
          success ::EE::API::Entities::GitlabSubscriptions::AddOnPurchase
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :quantity, type: Integer, desc: 'The quantity of the purchase'
          requires :expires_on, type: Date, desc: 'The date when purchase expires on'
          requires :purchase_xid, type: String, desc: 'The purchase identifier (example: the subscription name)'
        end
        post ":id/subscription_add_on_purchase/:add_on_name" do
          result = ::GitlabSubscriptions::AddOnPurchases::CreateService.new(
            @namespace,
            @add_on,
            declared_params
          ).execute

          if result[:status] == :success
            present result[:add_on_purchase], with: ::EE::API::Entities::GitlabSubscriptions::AddOnPurchase
          elsif result[:add_on_purchase].nil?
            bad_request!(result[:message])
          else
            render_validation_error!(result[:add_on_purchase])
          end
        end

        desc 'Returns an add-on purchase for the namespace' do
          detail 'Gets the add-on purchase record for the given namespace and add-on'
          success ::EE::API::Entities::GitlabSubscriptions::AddOnPurchase
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
        end
        get ":id/subscription_add_on_purchase/:add_on_name" do
          add_on_purchase = find_subscription_add_on_purchase!(@namespace, @add_on)

          present add_on_purchase, with: ::EE::API::Entities::GitlabSubscriptions::AddOnPurchase
        end

        desc 'Update the add-on purchase for the namespace' do
          detail 'Updates a subscription add-on record for the given namespaces and add-on'
          success ::EE::API::Entities::GitlabSubscriptions::AddOnPurchase
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :expires_on, type: Date, desc: 'The date when purchase expires on'
          optional :quantity, type: Integer, desc: 'The quantity of the purchase'
          optional :purchase_xid, type: String, desc: 'The purchase identifier (example: the subscription name)'
        end
        put ":id/subscription_add_on_purchase/:add_on_name" do
          result = ::GitlabSubscriptions::AddOnPurchases::UpdateService.new(
            @namespace,
            @add_on,
            declared_params
          ).execute

          if result[:status] == :success
            present result[:add_on_purchase], with: ::EE::API::Entities::GitlabSubscriptions::AddOnPurchase
          elsif result[:add_on_purchase].nil?
            bad_request!(result[:message])
          else
            render_validation_error!(result[:add_on_purchase])
          end
        end
      end
    end
  end
end
