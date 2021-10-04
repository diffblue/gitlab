# frozen_string_literal: true

module EE
  module MemberUserEntity
    extend ActiveSupport::Concern
    include ::Gitlab::Utils::StrongMemoize

    prepended do
      unexpose :gitlab_employee
      unexpose :email
      expose :oncall_schedules, with: ::IncidentManagement::OncallScheduleEntity
      expose :escalation_policies, with: ::IncidentManagement::EscalationPolicyEntity

      def oncall_schedules
        object.oncall_schedules.for_project(project_ids)
      end

      def escalation_policies
        object.escalation_policies.for_project(project_ids)
      end
    end

    private

    # options[:source] is required to scope oncall schedules or policies
    # It should be either a Group or Project
    def project_ids
      strong_memoize(:project_ids) do
        next [] unless options[:source].present?

        options[:source].is_a?(Group) ? options[:source].project_ids : [options[:source].id]
      end
    end
  end
end
