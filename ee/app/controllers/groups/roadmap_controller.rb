# frozen_string_literal: true

module Groups
  class RoadmapController < Groups::ApplicationController
    include IssuableCollections
    include EpicsActions

    before_action :check_epics_available!
    before_action :persist_roadmap_layout, only: [:show]
    before_action do
      push_frontend_feature_flag(:async_filtering, @group, default_enabled: true)
    end

    feature_category :roadmaps

    # show roadmap for a group
    def show
      # Used to persist the order and show the correct sorting dropdown on UI.
      @sort = set_sort_order
      @epics_state = epics_state_in_user_preference || 'all'
    end

    private

    def sorting_field
      :roadmaps_sort
    end

    def default_sort_value
      sort_value_start_date_soon
    end

    def remember_sorting_key(field = nil)
      @remember_sorting_key ||= "roadmap_sort"
    end

    def persist_roadmap_layout
      return unless current_user

      roadmap_layout = params[:layout]&.downcase

      return unless User.roadmap_layouts[roadmap_layout]
      return if current_user.roadmap_layout == roadmap_layout

      Users::UpdateService.new(current_user, user: current_user, roadmap_layout: roadmap_layout).execute
    end

    def epics_state_in_user_preference
      return unless current_user

      preference = current_user.user_preference

      if params[:state].present?
        preference.roadmap_epics_state = Epic.state_ids[params[:state]]

        preference.save if preference.changed? && Gitlab::Database.main.read_write?
      end

      Epic.state_ids.key(preference.roadmap_epics_state)
    end
  end
end
