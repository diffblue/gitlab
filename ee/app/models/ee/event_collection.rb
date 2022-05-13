# frozen_string_literal: true

module EE
  module EventCollection
    extend ::Gitlab::Utils::Override

    private

    override :project_and_group_events
    def project_and_group_events
      if EventFilter::GROUP_ONLY_EVENT_TYPES.include?(filter.filter)
        group_events
      else
        super
      end
    end
  end
end
