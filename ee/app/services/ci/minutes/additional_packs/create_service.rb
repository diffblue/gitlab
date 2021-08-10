# frozen_string_literal: true

module Ci
  module Minutes
    module AdditionalPacks
      class CreateService < ::Ci::Minutes::AdditionalPacks::BaseService
        def initialize(current_user, namespace, packs = [])
          @current_user = current_user
          @namespace = namespace
          @packs = packs
        end

        def execute
          authorize_current_user!

          Ci::Minutes::AdditionalPack.transaction do
            @additional_packs = packs.collect { |pack| find_or_create_pack!(pack) }

            reset_ci_minutes!
            successful_response
          end
        rescue ActiveRecord::RecordInvalid
          error_response
        end

        private

        attr_reader :current_user, :namespace, :packs, :additional_packs

        # rubocop: disable CodeReuse/ActiveRecord
        def find_or_create_pack!(pack)
          additional_pack = Ci::Minutes::AdditionalPack.find_or_initialize_by(
            namespace: namespace,
            purchase_xid: pack[:purchase_xid]
          )

          return additional_pack if additional_pack.persisted?

          additional_pack.update!(
            expires_at: pack[:expires_at],
            number_of_minutes: pack[:number_of_minutes]
          )

          additional_pack
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def successful_response
          success({ additional_packs: additional_packs })
        end

        def error_response
          error('Unable to save additional packs')
        end

        def reset_ci_minutes!
          ::Ci::Minutes::RefreshCachedDataService.new(namespace).execute
        end
      end
    end
  end
end
