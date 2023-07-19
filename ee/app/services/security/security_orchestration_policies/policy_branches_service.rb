# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class PolicyBranchesService < BaseProjectService
      include Gitlab::Utils::StrongMemoize

      def scan_execution_branches(rules)
        execute(:scan_execution, rules)
      end

      def scan_result_branches(rules)
        execute(:scan_result, rules)
      end

      private

      def execute(policy_type, rules)
        included_branches(policy_type, rules) - excluded_branches(rules)
      end

      def included_branches(policy_type, rules)
        return Set.new if rules.empty? || project.empty_repo?

        all_matched_branches = matched_branches(policy_type, rules)

        return all_matched_branches if policy_type == :scan_execution

        # Scan result policies can only affect protected branches
        all_matched_branches & matched_protected_branches
      end

      def excluded_branches(rules)
        return Set.new unless Feature.enabled?(:security_policies_branch_exceptions, project)

        rules.reduce(Set.new) do |set, rule|
          set.merge(match_exceptions(rule))
        end
      end

      def match_exceptions(rule)
        exceptions = rule[:branch_exceptions]

        return [] unless exceptions&.any?

        exceptions_for_project = exceptions.filter_map do |exception|
          case exception
          when String then exception
          when Hash then exception[:name] if exception[:full_path] == project.full_path
          end
        end

        all_branches_matched_by(exceptions_for_project)
      end

      def matched_branches(policy_type, rules)
        rules.reduce(Set.new) do |set, rule|
          set.merge(match_rule(policy_type, rule))
        end
      end

      def match_rule(policy_type, rule)
        return match_branch_types(rule[:branch_type]) if rule.key?(:branch_type)
        return match_branches(rule[:branches], policy_type) if rule.key?(:branches)

        []
      end

      def match_branch_types(branch_types)
        case branch_types
        when "all" then all_branch_names
        when "protected" then matched_protected_branches
        when "default" then [project.default_branch].compact
        else []
        end
      end

      def match_branches(branches, policy_type)
        return matched_protected_branches if policy_type == :scan_result && branches.empty?

        all_branches_matched_by(branches)
      end

      def matched_protected_branches
        all_branches_matched_by(all_protected_branch_names)
      end

      def all_branches_matched_by(patterns)
        patterns.flat_map do |pattern|
          RefMatcher.new(pattern).matching(all_branch_names)
        end
      end

      def all_branch_names
        repository.branch_names
      end
      strong_memoize_attr :all_branch_names

      def all_protected_branch_names
        project.all_protected_branches.pluck(:name) # rubocop: disable CodeReuse/ActiveRecord
      end
      strong_memoize_attr :all_protected_branch_names
    end
  end
end
