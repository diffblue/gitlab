# frozen_string_literal: true

module EE
  module BranchesHelper
    extend ::Gitlab::Utils::Override

    # Returns a hash were keys are types of access levels (user, role), and
    # values are the number of access levels of the particular type.
    def access_level_frequencies(access_levels)
      access_levels.each_with_object(Hash.new(0)) do |access_level, frequencies|
        frequencies[access_level.type] += 1
      end
    end

    override :access_levels_data
    def access_levels_data(access_levels)
      return [] unless access_levels

      access_levels.map do |level|
        case level.type
        when :user
          {
            id: level.id,
            type: level.type,
            user_id: level.user_id,
            username: level.user.username,
            name: level.user.name,
            avatar_url: level.user.avatar_url
          }
        when :deploy_key
          { id: level.id, type: level.type, deploy_key_id: level.deploy_key_id }
        when :group
          { id: level.id, type: level.type, group_id: level.group_id }
        else
          { id: level.id, type: level.type, access_level: level.access_level }
        end
      end
    end
  end
end
