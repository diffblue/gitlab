# frozen_string_literal: true

module Dast
  class ProfilesFinder
    DEFAULT_SORT = { id: :desc }.freeze

    def initialize(params = {})
      @params = params
    end

    def execute
      relation = default_relation
      relation = by_id(relation)
      relation = by_project(relation)
      relation = has_schedule?(relation)

      sort(relation)
    end

    private

    attr_reader :params

    def default_relation
      Dast::Profile.limit(100).with_schedule_owner
    end

    def by_id(relation)
      return relation if params[:id].nil?

      relation.id_in(params[:id])
    end

    def by_project(relation)
      return relation if params[:project_id].nil?

      relation.by_project_id(params[:project_id])
    end

    def has_schedule?(relation)
      return relation if params[:has_dast_profile_schedule].nil?

      relation.with_schedule(params[:has_dast_profile_schedule])
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def sort(relation)
      relation.order(DEFAULT_SORT)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
