# frozen_string_literal: true

module Groups
  class EpicsCountService < Groups::CountService
    private

    def cache_key_name
      'open_epics_count'
    end

    def relation_for_count
      EpicsFinder
        .new(user, group_id: group.id, state: 'opened')
        .execute(skip_visibility_check: true)
    end

    def issuable_key
      'open_epics'
    end
  end
end
