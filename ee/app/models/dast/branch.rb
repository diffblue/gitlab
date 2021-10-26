# rubocop:disable Naming/FileName
# frozen_string_literal: true

module Dast
  Branch = Struct.new(:profile) do
    delegate :project, to: :profile

    def name
      profile.branch_name || project.default_branch
    end

    def exists
      project.repository.branch_exists?(name)
    end
  end
end

# rubocop:enable Naming/FileName
