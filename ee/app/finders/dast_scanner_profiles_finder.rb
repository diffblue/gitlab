# frozen_string_literal: true

class DastScannerProfilesFinder
  def initialize(params = {})
    @params = params
  end

  def execute
    relation = init_collection
    relation = by_id(relation)
    relation = by_project(relation)
    relation = by_name(relation)
    relation.with_project
  end

  private

  attr_reader :params

  def init_collection
    DastScannerProfile.all
  end

  def by_id(relation)
    return relation unless params[:ids]

    relation.id_in(params[:ids])
  end

  def by_project(relation)
    if params[:project_ids]
      relation.project_id_in(params[:project_ids])
    elsif params[:project_id]
      relation.project_id_in(params[:project_id])
    else
      relation
    end
  end

  def by_name(relation)
    return relation unless params[:name]

    relation.with_name(params[:name])
  end
end
