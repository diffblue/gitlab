# frozen_string_literal: true

class DastSiteProfilesFinder
  def initialize(params = {})
    @params = params
  end

  def execute
    relation = DastSiteProfile.with_dast_site_and_validation
    relation = by_id(relation)
    relation = by_project(relation)
    relation = by_name(relation)
    relation.with_project
  end

  private

  attr_reader :params

  def by_id(relation)
    return relation if params[:id].nil?

    relation.id_in(params[:id]).limit(1)
  end

  def by_project(relation)
    return relation if params[:project_id].nil?

    relation.with_project_id(params[:project_id])
  end

  def by_name(relation)
    return relation unless params[:name]

    relation.with_name(params[:name])
  end
end
