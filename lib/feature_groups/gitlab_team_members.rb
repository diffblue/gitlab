# frozen_string_literal: true

module FeatureGroups
  class GitlabTeamMembers
    def self.enabled?(_)
      false
    end
  end
end

FeatureGroups::GitlabTeamMembers.prepend_mod
