# frozen_string_literal: true

module EE
  module Projects
    module WikiRepository
      extend ActiveSupport::Concern

      prepended do
        has_one :wiki_repository_state,
                class_name: 'Geo::WikiRepositoryState',
                foreign_key: :project_wiki_repository_id,
                inverse_of: :project_wiki_repository,
                autosave: false
      end

      class_methods do
        def verification_state_value(state_string)
          ::Geo::VerificationState::VERIFICATION_STATE_VALUES[state_string]
        end
      end
    end
  end
end
