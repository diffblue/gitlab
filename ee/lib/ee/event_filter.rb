# frozen_string_literal: true

module EE
  module EventFilter
    extend ::Gitlab::Utils::Override

    EPIC = 'epic'

    override :apply_filter
    def apply_filter(events)
      case filter
      when EPIC
        events.epics
      else
        super
      end
    end

    def in_operator_query_builder_params(user_ids)
      case filter
      when EPIC
        in_operator_params(
          array_scope_ids: user_ids,
          scope: ::Event.epics,
          in_column: :action,
          in_values: ::Event.actions.values_at(*::Event::EPIC_ACTIONS)
        )
      else
        super
      end
    end

    private

    override :filters
    def filters
      super << EPIC
    end
  end
end
