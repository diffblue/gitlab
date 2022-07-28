# frozen_string_literal: true

module EE
  module Ci
    module RunnerPolicy
      extend ActiveSupport::Concern

      prepended do
        condition(:is_group_runner) do
          @subject.group_type?
        end

        condition(:is_project_runner) do
          @subject.project_type?
        end

        condition(:enable_auditor_group_runner_access) do
          ::Feature.enabled?(:auditor_group_runner_access)
        end

        rule { enable_auditor_group_runner_access & auditor & (is_group_runner | is_project_runner) }.policy do
          enable :read_runner
        end
      end
    end
  end
end
