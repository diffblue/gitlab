# frozen_string_literal: true

module EE
  module Ci
    module RunnerPolicy
      extend ActiveSupport::Concern

      prepended do
        condition(:is_group_runner, scope: :subject) do
          @subject.group_type?
        end

        condition(:is_project_runner, scope: :subject) do
          @subject.project_type?
        end

        rule { auditor & (is_group_runner | is_project_runner) }.policy do
          enable :read_runner
        end
      end
    end
  end
end
