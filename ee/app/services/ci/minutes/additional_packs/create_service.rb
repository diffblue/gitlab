# frozen_string_literal: true

module Ci
  module Minutes
    module AdditionalPacks
      class CreateService < ::Ci::Minutes::AdditionalPacks::BaseService
        def initialize(current_user, namespace, params = {})
          @current_user = current_user
          @namespace = namespace
          @purchase_xid = params[:purchase_xid]
          @expires_at = params[:expires_at]
          @number_of_minutes = params[:number_of_minutes]
        end

        def execute
          authorize_current_user!

          if additional_pack.persisted? || save_additional_pack
            reset_ci_minutes!

            successful_response
          else
            error_response
          end
        end

        private

        attr_reader :current_user, :namespace, :purchase_xid, :expires_at, :number_of_minutes

        # rubocop: disable CodeReuse/ActiveRecord
        def additional_pack
          @additional_pack ||= Ci::Minutes::AdditionalPack.find_or_initialize_by(
            namespace: namespace,
            purchase_xid: purchase_xid
          )
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def save_additional_pack
          additional_pack.assign_attributes(
            expires_at: expires_at,
            number_of_minutes: number_of_minutes
          )

          additional_pack.save
        end

        def successful_response
          success({ additional_pack: additional_pack })
        end

        def error_response
          error('Unable to save additional pack')
        end

        def reset_ci_minutes!
          ::Ci::Minutes::RefreshCachedDataService.new(namespace).execute
        end
      end
    end
  end
end
