# frozen_string_literal: true

module EE
  module SnippetsFinder
    extend ::Gitlab::Utils::Override

    attr_reader :authorized_and_user_personal

    def initialize(current_user = nil, params = {})
      super

      @authorized_and_user_personal = params[:authorized_and_user_personal]
    end

    private

    override :init_collection
    def init_collection
      return snippets_of_authorized_projects_or_personal if authorized_and_user_personal.present?

      super
    end

    # This method returns snippets from a more restrictive scope.
    # When current_user is not nil we return the personal snippets
    # authored by the user and also snippets from the authorized projects.
    #
    # When current_user is nil it returns only public personal snippets
    def snippets_of_authorized_projects_or_personal
      queries = []
      queries << restricted_personal_snippets unless only_project?

      if current_user && Ability.allowed?(current_user, :read_cross_project)
        queries << snippets_of_authorized_projects unless only_personal?
      end

      prepared_union(queries)
    end

    def restricted_personal_snippets
      if author
        snippets_for_author
      elsif current_user
        current_user.snippets
      else
        ::Snippet.public_to_user
      end.only_personal_snippets
    end
  end
end
