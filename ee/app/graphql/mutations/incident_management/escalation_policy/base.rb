# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module EscalationPolicy
      class Base < BaseMutation
        field :escalation_policy,
              ::Types::IncidentManagement::EscalationPolicyType,
              null: true,
              description: 'Escalation policy.'

        authorize :admin_incident_management_escalation_policy

        private

        def response(result)
          {
            escalation_policy: result.payload[:escalation_policy],
            errors: result.errors
          }
        end

        def find_object(id:)
          GitlabSchema.object_from_id(id, expected_type: ::IncidentManagement::EscalationPolicy).sync
        end

        # Provide more granular error message for feature availability
        # ahead of role-based authorization
        def authorize!(object)
          raise_feature_not_available! if object && !escalation_policies_available?(object)

          super
        end

        def raise_feature_not_available!
          raise_resource_not_available_error! 'Escalation policies are not supported for this project'
        end

        def escalation_policies_available?(policy)
          ::Gitlab::IncidentManagement.escalation_policies_available?(policy.project)
        end

        def prepare_rules_attributes(project, args)
          return args unless rules = args.delete(:rules)

          schedules = find_schedules(project, rules)
          users = find_users(rules)
          rules_attributes = rules.map { |rule| prepare_rule(rule.to_h, schedules, users) }

          args.merge(rules_attributes: rules_attributes)
        end

        def prepare_rule(rule, schedules, users)
          iid = rule.delete(:oncall_schedule_iid).to_i
          username = rule.delete(:username)

          rule.merge(
            oncall_schedule: schedules[iid],
            user: users[username]
          )
        end

        def find_schedules(project, rules)
          find_resource(rules, :oncall_schedule_iid) do |iids|
            ::IncidentManagement::OncallSchedulesFinder.new(current_user, project, iid: iids).execute.index_by(&:iid)
          end
        end

        def find_users(rules)
          find_resource(rules, :username) do |usernames|
            UsersFinder.new(current_user, username: usernames).execute.index_by(&:username)
          end
        end

        def find_resource(rules, attribute)
          identifiers = rules.collect { |rule| rule[attribute] }.uniq.compact
          resources = yield(identifiers)

          return resources if resources.length == identifiers.length

          raise_resource_not_available_error!
        end
      end
    end
  end
end
