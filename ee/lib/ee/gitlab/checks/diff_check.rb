# frozen_string_literal: true

module EE
  module Gitlab
    module Checks
      module DiffCheck
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        private

        def file_paths_validations
          validations = [super].flatten

          if validate_code_owners?
            validations << validate_code_owners
          end

          validations
        end

        def validate_code_owners?
          return false if updated_from_web? || user_access.can_push_to_branch?(branch_name)

          project.branch_requires_code_owner_approval?(branch_name)
        end

        def validate_code_owners
          lambda do |paths|
            validator = ::Gitlab::CodeOwners::Validator.new(project, branch_name, paths)

            validator.execute
          end
        end

        def validate_path_locks?
          strong_memoize(:validate_path_locks) do
            project.feature_available?(:file_locks) &&
              project.any_path_locks? &&
              project.default_branch == branch_name # locks protect default branch only
          end
        end

        def push_rule_checks_commit?
          return false unless push_rule

          push_rule.file_name_regex.present? || push_rule.prevent_secrets
        end

        override :validations_for_path
        def validations_for_path
          super.tap do |validations|
            validations.push(path_locks_validation) if validate_path_locks?
            validations.push(file_name_validation) if push_rule_checks_commit?
          end
        end

        def path_locks_validation
          lambda do |changed_path|
            path = changed_path.path
            lock_info = project.find_path_lock(path)

            if lock_info && lock_info.user != user_access.user
              return "The path '#{lock_info.path}' is locked by #{lock_info.user.name}"
            end
          end
        end

        def file_name_validation
          lambda do |changed_path|
            if changed_path.new_file? && denylisted_regex = push_rule.filename_denylisted?(changed_path.path)
              return unless denylisted_regex.present?

              "File name #{changed_path.path} was prohibited by the pattern #{denylisted_regex.inspect}."
            end
          rescue ::PushRule::MatchError => e
            raise ::Gitlab::GitAccess::ForbiddenError, e.message
          end
        end
      end
    end
  end
end
