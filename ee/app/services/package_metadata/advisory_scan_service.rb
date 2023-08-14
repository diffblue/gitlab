# frozen_string_literal: true

module PackageMetadata
  class AdvisoryScanService
    def self.execute(_advisory)
      raise NoMethodError, 'To be implemented in https://gitlab.com/gitlab-org/gitlab/-/issues/371065'
    end
  end
end
