# frozen_string_literal: true

module IncidentManagement
  class IssuableResourceLinkPolicy < ::BasePolicy
    delegate { @subject.issue }
  end
end
