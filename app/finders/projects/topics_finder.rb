# frozen_string_literal: true

# Projects::TopicsFinder
#
# Used to filter Topics (ActsAsTaggableOn::Tag) by a set of params
#
# Arguments:
#   current_user - which user is requesting groups
#   params:
#     all_available: boolean (defaults to true)
#     name: string
#     sort: string
module Projects
  class TopicsFinder
    attr_reader :current_user, :params

    def initialize(current_user: nil, params: {})
      @current_user = current_user
      @params = params
    end

    def execute
      projects_relation.tag_counts_on(:topics, options)
    end

    private

    def projects_relation
      if current_user.nil? || all_available?
        Project.public_or_visible_to_user(current_user)
      else
        current_user.authorized_projects
      end
    end

    def all_available?
      params.fetch(:all_available, true)
    end

    def options
      {
        conditions: filter_by_name,
        order: sort_by_attribute
      }
    end

    def filter_by_name
      ActsAsTaggableOn::Tag.arel_table[:name].matches("%#{params[:name]}%") if params[:name].present?
    end

    def sort_by_attribute
      case params[:sort]
      when 'name_asc'        then 'tags.name asc'
      when 'name_desc'       then 'tags.name desc'
      when 'popularity_desc' then 'count desc'
      else
        'count desc'
      end
    end
  end
end
