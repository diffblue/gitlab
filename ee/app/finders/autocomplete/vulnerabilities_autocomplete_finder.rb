# frozen_string_literal: true

module Autocomplete
  class VulnerabilitiesAutocompleteFinder
    attr_reader :current_user, :vulnerable, :params

    # current_user - the User object of the user that wants to view the list of Vulnerabilities
    #
    # vulnerable - any object that has a #vulnerabilities method that returns a collection of vulnerabilitie
    # params - a Hash containing additional parameters to set
    #
    # The supported parameters are those supported by
    # `Security::VulnerabilitiesFinder`.
    def initialize(current_user, vulnerable, params = {})
      @current_user = current_user
      @vulnerable = vulnerable
      @params = params
    end

    DEFAULT_AUTOCOMPLETE_LIMIT = 5

    def execute
      return ::Vulnerability.none unless current_user && vulnerable.feature_available?(:security_dashboard)

      ::Security::VulnerabilitiesFinder # rubocop: disable CodeReuse/Finder
        .new(vulnerable)
        .execute
        .autocomplete_search(params[:search].to_s)
        .with_limit(DEFAULT_AUTOCOMPLETE_LIMIT)
        .order_id_desc
        .visible_to_user_and_access_level(current_user, ::Gitlab::Access::DEVELOPER)
    end
  end
end
