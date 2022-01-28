# frozen_string_literal: true

module EE::Gitlab::Analytics::CycleAnalytics::Aggregated::BaseQueryBuilder
  extend ::Gitlab::Utils::Override

  override :build
  def build
    filter_by_project_ids(super)
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
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def in_optimization_array_scope
    projects_filter_present? ? project_ids : stage.parent.self_and_descendant_ids.reselect(:id)
  end

  # rubocop: disable CodeReuse/ActiveRecord
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
