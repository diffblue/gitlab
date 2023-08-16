# frozen_string_literal: true

module EE
  module Noteable
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    class_methods do
      # We can't specify `override` here:
      # https://gitlab.com/gitlab-org/gitlab-foss/issues/50911
      def replyable_types
        super + %w[Epic Vulnerability]
      end
    end

    private

    override :synthetic_note_ids_relations
    def synthetic_note_ids_relations
      relations = super

      if respond_to?(:resource_weight_events)
        relations << resource_weight_events.select(
          "'resource_weight_events'", :id, :created_at, 'ARRAY_FILL(id, ARRAY[1])'
        )
      end

      if respond_to?(:resource_iteration_events)
        relations << resource_iteration_events.select(
          "'resource_iteration_events'", :id, :created_at, 'ARRAY_FILL(id, ARRAY[1])'
        )
      end

      relations
    end
  end
end
