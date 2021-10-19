# frozen_string_literal: true

module EE::Gitlab::Analytics::CycleAnalytics::Aggregated::BaseQueryBuilder
  extend ::Gitlab::Utils::Override

  override :build
  def build
    filter_by_project_ids(super)
  end

  private

  override :filter_by_stage_parent
  def filter_by_stage_parent(query)
    return super unless stage.parent.instance_of?(Group)

    query.by_group_id(stage.parent.self_and_descendant_ids)
  end

  def filter_by_project_ids(query)
    return query unless stage.parent.instance_of?(Group)
    return query if params[:project_ids].blank?

    project_ids = Project
      .id_in(params[:project_ids])
      .in_namespace(stage.parent.self_and_descendant_ids)
      .select(:id)

    return query if project_ids.empty?

    query.by_project_id(project_ids)
  end
end
