# frozen_string_literal: true

module Onboarding
  module LearnGitlab
    def self.available?(namespace, user)
      return false unless user

      ::Onboarding::Progress.onboarding?(namespace)
    end
  end
end
