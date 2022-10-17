# frozen_string_literal: true

module Geo
  class ProjectWikiRepositoryRegistry < Geo::BaseRegistry
    MODEL_CLASS = ::Project
    MODEL_FOREIGN_KEY = :project_id

    belongs_to :project, class_name: 'Project'
  end
end
