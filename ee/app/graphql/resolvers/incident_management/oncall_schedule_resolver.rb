# frozen_string_literal: true

module Resolvers
  module IncidentManagement
    class OncallScheduleResolver < BaseResolver
      extend ::Gitlab::Utils::Override
      include LooksAhead

      alias_method :project, :object

      type Types::IncidentManagement::OncallScheduleType.connection_type, null: true

      argument :iids, [GraphQL::Types::ID],
               required: false,
               description: 'IIDs of on-call schedules.'

      def resolve_with_lookahead(**args)
        apply_lookahead(::IncidentManagement::OncallSchedulesFinder.new(context[:current_user], project, iid: args[:iids]).execute)
      end

      private

      # Tailor preloads to requested rotation fields instead of
      # using LooksAhead#preloads to bulk-load all rotation associations
      override :filtered_preloads
      def filtered_preloads
        rotation = rotation_selection

        return [] unless rotation
        return [{ rotations: { active_participants: :user } }] if rotation.selects?(:participants)
        return [{ rotations: :active_participants }] if will_generate_shifts?(rotation)

        [:rotations]
      end

      # @param rotation [GraphQL::Execution::Lookahead]
      def will_generate_shifts?(rotation)
        return false unless rotation.selects?(:shifts)

        rotation.selection(:shifts).arguments[:end_time] > Time.current
      end

      def rotation_selection
        rotations = node_selection&.selection(:rotations)
        return unless rotations&.selected?

        if rotations.selects?(:nodes)
          rotations.selection(:nodes)
        elsif rotations.selects?(:edges)
          rotations.selection(:edges).selection(:node)
        end
      end
    end
  end
end
