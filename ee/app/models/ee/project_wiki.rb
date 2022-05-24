# frozen_string_literal: true

module EE
  module ProjectWiki
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      # TODO: Move this into EE::Wiki once we implement ES support for group wikis.
      # https://gitlab.com/gitlab-org/gitlab/-/issues/207889
      include Elastic::WikiRepositoriesSearch
    end

    override :after_wiki_activity
    def after_wiki_activity
      super

      project.repository_state&.touch(:last_wiki_updated_at)
    end
  end
end
