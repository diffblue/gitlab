# frozen_string_literal: true

module EE::Gitlab::Analytics::CycleAnalytics::Aggregated::BaseQueryBuilder
  extend ::Gitlab::Utils::Override

  override :build
  def build
    query = filter_by_project_ids(super)
    query = filter_by_weight(query)
    query = filter_by_iteration(query)
    query = filter_by_epic(query)
    filter_by_my_reaction_emoji(query)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def build_sorted_query
    return super unless stage.parent.instance_of?(Group)

    ::Gitlab::Pagination::Keyset::InOperatorOptimization::QueryBuilder.new(
      scope: super.unscope(where: [:project_id, :group_id]), # unscoping the project_id and group_id queries because the in-operator optimization will apply these filters.
      array_scope: in_optimization_array_scope,
      array_mapping_scope: method(:in_optimization_array_mapping_scope)
    ).execute
  end

  private

  def filter_by_weight(query)
    return query unless issue_based_stage?
    return query unless params[:weight]

    query.where(weight: params[:weight])
  end

  def filter_by_iteration(query)
    return query unless issue_based_stage?
    return query unless params[:iteration_id]

    query.where(sprint_id: params[:iteration_id])
  end

  def filter_by_epic(query)
    return query unless issue_based_stage?
    return query unless params[:epic_id]

    query.joins(:epic_issue).where(epic_issues: { epic_id: params[:epic_id] })
  end

  def filter_by_my_reaction_emoji(query)
    return query unless issue_based_stage?
    return query unless params[:my_reaction_emoji]

    query.awarded(
      params[:current_user],
      params[:my_reaction_emoji],
      ::Issue.name,
      :issue_id
    )
  end

  def issue_based_stage?
    stage.subject_class == ::Issue
  end

  def in_optimization_array_scope
    projects_filter_present? ? project_ids : stage.parent.self_and_descendant_ids.reselect(:id)
  end

  def in_optimization_array_mapping_scope(id_expression)
    issuable_id_column = projects_filter_present? ? :project_id : :group_id
    stage_event_model.where(stage_event_model.arel_table[issuable_id_column].eq(id_expression))
  end
  # rubocop: enable CodeReuse/ActiveRecord

  override :filter_by_stage_parent
  def filter_by_stage_parent(query)
    return super unless stage.parent.instance_of?(Group)

    query.by_group_id(stage.parent.self_and_descendant_ids)
  end

  def filter_by_project_ids(query)
    return query unless stage.parent.instance_of?(Group)
    return query unless projects_filter_present?

    query.by_project_id(project_ids)
  end

  def project_ids
    @project_ids ||= Project
      .id_in(params[:project_ids])
      .in_namespace(stage.parent.self_and_descendant_ids)
      .select(:id)
  end

  def projects_filter_present?
    Array(params[:project_ids]).any?
  end
end
