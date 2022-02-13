# frozen_string_literal: true

module Vulnerabilities
  class BaseService
    include Gitlab::Allowable

    def initialize(user, vulnerability)
      @user = user
      @vulnerability = vulnerability
      @project = vulnerability.project
    end

    private

    def update_with_note(vulnerability, params)
      return false unless vulnerability.update(params)

      Vulnerabilities::Statistics::UpdateService.update_for(vulnerability)
      SystemNoteService.change_vulnerability_state(vulnerability, @user) if vulnerability.state_previously_changed?
      true
    end

    def authorized?
      can?(@user, :admin_vulnerability, @project)
    end
  end
end
