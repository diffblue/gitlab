# frozen_string_literal: true

module Vulnerabilities
  class ProjectsGrade
    attr_reader :vulnerable, :grade, :project_ids, :include_subgroups

    # project_ids can contain IDs from projects that do not belong to vulnerable, they will be filtered out in `projects` method
    def initialize(vulnerable, letter_grade, project_ids = [], include_subgroups: false)
      @vulnerable = vulnerable
      @grade = letter_grade
      @project_ids = project_ids
      @include_subgroups = include_subgroups
    end

    delegate :count, to: :projects

    def projects
      return Project.none if project_ids.blank?

      projects = include_subgroups ? vulnerable.all_projects : vulnerable.projects
      projects.with_vulnerability_statistics.inc_routes.where(id: project_ids)
    end

    def self.grades_for(vulnerables, filter: nil, include_subgroups: false)
      projects = include_subgroups ? vulnerables.map(&:all_projects) : vulnerables.map(&:projects)

      relation = ::Vulnerabilities::Statistic.for_project(projects.reduce(&:or))
      relation = relation.by_grade(filter) if filter

      relation.group(:letter_grade)
              .select(:letter_grade, 'array_agg(project_id) project_ids')
              .then do |statistics|
                vulnerables.index_with do |vulnerable|
                  statistics.map { |statistic| new(vulnerable, statistic.letter_grade, statistic.project_ids, include_subgroups: include_subgroups) }
                end
              end
    end
  end
end
