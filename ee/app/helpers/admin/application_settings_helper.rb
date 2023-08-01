# frozen_string_literal: true

module Admin
  module ApplicationSettingsHelper
    # rubocop:disable Layout/LineLength
    # rubocop:disable Style/FormatString
    # rubocop:disable Rails/OutputSafety
    # We extracted Code Suggestions tooltips/texts generation to this helper from the views, to make them lightweight.
    # Rubocop would not consider LineLength, FormatString, OutputSafety problematic if it stayed in the view.
    # We decided that it is worth extracting this logic here and silencing Rubocop just for code_suggestions_* helpers.
    def code_suggestions_description
      link_start = code_suggestions_link_start(code_suggestions_docs_url)

      s_('CodeSuggestionsSM|Enable Code Suggestions for users of this instance. %{link_start}What are Code Suggestions?%{link_end}')
        .html_safe % { link_start: link_start, link_end: '</a>'.html_safe }
    end

    def code_suggestions_token_explanation
      link_start = code_suggestions_link_start(code_suggestions_pat_docs_url)

      s_('CodeSuggestionsSM|On GitLab.com, create a token. This token is required to use Code Suggestions on your self-managed instance. %{link_start}How do I create a token?%{link_end}')
        .html_safe % { link_start: link_start, link_end: '</a>'.html_safe }
    end

    def code_suggestions_agreement
      terms_link_start = code_suggestions_link_start(code_suggestions_agreement_url)
      ai_docs_link_start = code_suggestions_link_start(code_suggestions_ai_docs_url)

      s_('CodeSuggestionsSM|By enabling this feature, you agree to the %{terms_link_start}GitLab Testing Agreement%{link_end} and acknowledge that GitLab will send data from the instance, including personal data, to our %{ai_docs_link_start}AI providers%{link_end} to provide this feature.')
        .html_safe % { terms_link_start: terms_link_start, ai_docs_link_start: ai_docs_link_start, link_end: '</a>'.html_safe }
    end
    # rubocop:enable Layout/LineLength
    # rubocop:enable Style/FormatString
    # rubocop:enable Rails/OutputSafety

    private

    # rubocop:disable Gitlab/DocUrl
    # We want to link SaaS docs for flexibility for every URL related to Code Suggestions on Self Managed.
    # We expect to update docs often during the Beta and we want to point user to the most up to date information.
    def code_suggestions_docs_url
      'https://docs.gitlab.com/ee/user/project/repository/code_suggestions.html'
    end

    def code_suggestions_agreement_url
      'https://about.gitlab.com/handbook/legal/testing-agreement/'
    end

    def code_suggestions_ai_docs_url
      'https://docs.gitlab.com/ee/user/ai_features.html#third-party-services'
    end

    def code_suggestions_pat_docs_url
      'https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#create-a-personal-access-token'
    end
    # rubocop:enable Gitlab/DocUrl

    # rubocop:disable Rails/OutputSafety
    def code_suggestions_link_start(url)
      "<a href=\"#{url}\" target=\"_blank\" rel=\"noopener noreferrer\">".html_safe
    end
    # rubocop:enable Rails/OutputSafety
  end
end
