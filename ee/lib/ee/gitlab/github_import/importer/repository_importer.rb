# frozen_string_literal: true

module EE
  module Gitlab
    module GithubImport
      module Importer
        module RepositoryImporter
          extend ::Gitlab::Utils::Override

          override :validate_repository_size!
          def validate_repository_size!
            ::Import::ValidateRepositorySizeService.new(project).execute
          end
        end
      end
    end
  end
end
