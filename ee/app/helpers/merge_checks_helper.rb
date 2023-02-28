# frozen_string_literal: true

module MergeChecksHelper
  def merge_checks(source)
    case source
    when Group
      target = source.namespace_settings
      source_type = 'namespace_setting'
      parent_group_name = source.parent.nil? ? '' : source.parent.name
    when Project
      target = source
      source_type = 'project'
      # When the project has no group it should be an empty strings
      parent_group_name = source.group.nil? ? '' : source.group.name
    end

    {
      source_type: source_type,
      settings: {
        pipeline_must_succeed: {
          locked: target.only_allow_merge_if_pipeline_succeeds_locked?,
          value: target.only_allow_merge_if_pipeline_succeeds?(inherit_group_setting: true)
        },
        allow_merge_on_skipped_pipeline: {
          locked: target.allow_merge_on_skipped_pipeline_locked?,
          value: target.allow_merge_on_skipped_pipeline?(inherit_group_setting: true)
        },
        only_allow_merge_if_all_resolved: {
          locked: target.only_allow_merge_if_all_discussions_are_resolved_locked?,
          value: target.only_allow_merge_if_all_discussions_are_resolved?(inherit_group_setting: true)
        }
      }.to_json,
      parent_group_name: parent_group_name
    }
  end
end
