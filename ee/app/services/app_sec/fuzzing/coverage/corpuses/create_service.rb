# frozen_string_literal: true

module AppSec
  module Fuzzing
    module Coverage
      module Corpuses
        class CreateService < BaseProjectService
          def execute
            return ServiceResponse.error(message: 'Insufficient permissions') unless allowed?

            corpus = AppSec::Fuzzing::Coverage::Corpus.new(
              project: project,
              user: current_user,
              package_id: params.fetch(:package_id)
            )

            if corpus.save
              create_audit_event(corpus)

              return ServiceResponse.success(
                payload: {
                  corpus: corpus
                }
              )
            end

            ServiceResponse.error(message: corpus.errors.full_messages)
          rescue KeyError => err
            ServiceResponse.error(message: err.message.capitalize)
          end

          private

          def allowed?
            project.licensed_feature_available?(:coverage_fuzzing)
          end

          def create_audit_event(corpus)
            ::Gitlab::Audit::Auditor.audit(
              name: 'coverage_fuzzing_corpus_create',
              author: current_user,
              scope: project,
              target: corpus,
              message: 'Added Coverage Fuzzing Corpus'
            )
          end
        end
      end
    end
  end
end
