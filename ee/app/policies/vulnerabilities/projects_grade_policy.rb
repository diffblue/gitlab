# frozen_string_literal: true

module Vulnerabilities
  class ProjectsGradePolicy < BasePolicy
    delegate { @subject.vulnerable }
  end
end
