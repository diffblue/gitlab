# frozen_string_literal: true

module Autocomplete
  class GroupSubgroupsFinder
    attr_reader :current_user, :params

    LIMIT = 50

    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params
    end

    # rubocop: disable CodeReuse/Finder
    def execute
      group = ::Autocomplete::GroupFinder.new(current_user, nil, params).execute
      GroupsFinder.new(current_user, parent: group).execute.limit(LIMIT)
    end
    # rubocop: enable CodeReuse/Finder
  end
end
