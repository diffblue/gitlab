# frozen_string_literal: true

module Geo
  # Used to provide registry data for GraphQL queries.
  #
  module FrameworkRegistryFinder
    extend ActiveSupport::Concern

    included do
      include Gitlab::Allowable

      delegate :registry_class, to: :replicator_class

      def initialize(current_user, params = {})
        @current_user = current_user
        @params = params
      end

      def execute
        return registry_class.none unless can?(current_user, :read_all_geo)

        registry_entries = init_collection
        registry_entries = by_id(registry_entries)
        registry_entries = by_replication_state(registry_entries)
        registry_entries = by_verification_state(registry_entries)
        registry_entries = by_keyword(registry_entries)
        registry_entries.ordered
      end

      private

      attr_reader :current_user, :params

      def replicator_class
        Gitlab::Geo::Replicator.for_class_name(self.class.name)
      end

      def verification_disabled?
        !replicator_class.verification_enabled?
      end

      def init_collection
        registry_class.all
      end

      def by_id(registry_entries)
        return registry_entries if params[:ids].blank?

        registry_entries.id_in(params[:ids])
      end

      def by_replication_state(registry_entries)
        return registry_entries if params[:replication_state].blank?

        registry_entries.with_state(params[:replication_state])
      end

      def by_verification_state(registry_entries)
        if verification_disabled? && params.key?(:verification_state)
          raise ArgumentError, "Filtering by verification_state is not supported " \
            "because verification is not enabled for #{replicator_class.model}"
        end

        return registry_entries if params[:verification_state].blank?

        registry_entries.public_send("verification_#{params[:verification_state]}") # rubocop:disable GitlabSecurity/PublicSend
      end

      def by_keyword(registry_entries)
        return registry_entries if params[:keyword].blank?

        unless replicator_class.model.respond_to?(:search)
          raise ArgumentError, "Filtering by keyword is not supported " \
                "because search method is not implemented for #{replicator_class.model}"
        end

        registry_entries.with_search(params[:keyword])
      end
    end
  end
end
