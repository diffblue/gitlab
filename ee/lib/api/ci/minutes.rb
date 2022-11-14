# frozen_string_literal: true

module API
  module Ci
    class Minutes < ::API::Base
      feature_category :purchase
      urgency :low

      CI_MINUTES_TAGS = %w[ci_minutes].freeze

      before { authenticated_as_admin! }

      resource :namespaces, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Create a CI Minutes purchase record for the namespace' do
          detail 'Creates an additional pack'
          success ::EE::API::Entities::Ci::Minutes::AdditionalPack
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          is_array true
          tags CI_MINUTES_TAGS
        end
        params do
          requires :id, type: String, desc: 'The ID of a namespace'
          requires :packs, type: Array, desc: 'An array of additional purchased minutes packs' do
            requires :number_of_minutes, type: Integer, desc: 'Number of additional minutes purchased'
            requires :expires_at, type: Date, desc: 'The expiry date for the purchase'
            requires :purchase_xid, type: String, desc: 'Purchase ID for the additional minutes'
          end
        end
        post ':id/minutes' do
          namespace = find_namespace(params[:id])
          not_found!('Namespace') unless namespace

          result = ::Ci::Minutes::AdditionalPacks::CreateService.new(current_user, namespace, params[:packs]).execute

          if result[:status] == :success
            present result[:additional_packs], with: ::EE::API::Entities::Ci::Minutes::AdditionalPack
          else
            bad_request!(result[:message])
          end
        end

        desc 'Transfer purchased CI minutes packs to another namespace' do
          detail 'Moves additional packs from one namespace to another'
          success code: 202
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          tags CI_MINUTES_TAGS
        end
        params do
          requires :id, type: String, desc: 'The ID of the namespace to transfer from'
          requires :target_id, type: String, desc: 'The ID of the namespace for the packs to transfer to'
        end
        patch ':id/minutes/move/:target_id' do
          namespace = find_namespace(params[:id])
          target_namespace = find_namespace(params[:target_id])

          not_found!('Namespace') unless namespace
          not_found!('Target namespace') unless target_namespace

          result = ::Ci::Minutes::AdditionalPacks::ChangeNamespaceService.new(current_user, namespace, target_namespace).execute

          if result[:status] == :success
            accepted!
          else
            bad_request!(result[:message])
          end
        end
      end
    end
  end
end
