# frozen_string_literal: true

module Mutations
  module AppSec::Fuzzing::Coverage
    module Corpus
      class Create < BaseMutation
        graphql_name 'CorpusCreate'

        include FindsProject

        authorize :create_coverage_fuzzing_corpus

        argument :package_id, Types::GlobalIDType[::Packages::Package],
              required: true,
              description: 'ID of the corpus package.'

        argument :full_path, GraphQL::Types::ID,
                 required: true,
                 description: 'Project the corpus belongs to.'

        def resolve(full_path:, package_id:)
          project = authorized_find!(full_path)

          response = ::AppSec::Fuzzing::Coverage::Corpuses::CreateService.new(
            project: project,
            current_user: current_user,
            params: {
              package_id: Gitlab::Graphql::Lazy.force(GitlabSchema.find_by_gid(package_id))&.id
            }
          ).execute

          return { errors: response.errors } if response.error?

          build_response(response.payload)
        end

        private

        def build_response(payload)
          {
            errors: [],
            corpus: payload.fetch(:corpus)
          }
        end
      end
    end
  end
end
