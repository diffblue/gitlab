# frozen_string_literal: true

module EE
  module Note
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include ::ObjectStorage::BackgroundMove
      include Elastic::ApplicationVersionedSearch
      include UsageStatistics

      scope :searchable, -> { where(system: false).includes(:noteable) }
      scope :by_humans, -> { user.joins(:author).merge(::User.humans) }
      scope :count_for_vulnerability_id, ->(vulnerability_id) do
        where(noteable_type: ::Vulnerability.name, noteable_id: vulnerability_id)
          .group(:noteable_id)
          .count
      end
    end

    class_methods do
      # override
      def use_separate_indices?
        Elastic::DataMigrationService.migration_has_finished?(:migrate_notes_to_separate_index)
      end
    end

    # Original method in Elastic::ApplicationSearch
    def searchable?
      !system && super
    end

    def for_epic?
      noteable.is_a?(Epic)
    end

    def for_vulnerability?
      noteable.is_a?(Vulnerability)
    end

    override :for_project_noteable?
    def for_project_noteable?
      !for_epic? && super
    end

    override :banzai_render_context
    def banzai_render_context(field)
      return super unless for_epic?

      super.merge(banzai_context_params)
    end

    override :mentionable_params
    def mentionable_params
      return super unless for_epic?

      super.merge(banzai_context_params)
    end

    override :for_issuable?
    def for_issuable?
      for_epic? || super
    end

    override :resource_parent
    def resource_parent
      for_epic? ? noteable.group : super
    end

    override :system_note_visible_for?
    def system_note_visible_for?(user)
      return false unless super

      return true unless system_note_for_epic? && created_before_noteable?

      group_reporter?(user, noteable.group)
    end

    override :skip_notification?
    def skip_notification?
      for_vulnerability? || super
    end

    def usage_ping_track_updated_epic_note(user)
      ::Gitlab::UsageDataCounters::EpicActivityUniqueCounter.track_epic_note_updated_action(author: user) if for_epic?
    end

    private

    def system_note_for_epic?
      system? && for_epic?
    end

    def created_before_noteable?
      created_at.to_i < noteable.created_at.to_i
    end

    def group_reporter?(user, group)
      group.max_member_access_for_user(user) >= ::Gitlab::Access::REPORTER
    end

    def banzai_context_params
      { group: noteable.group, label_url_method: :group_epics_url }
    end
  end
end
