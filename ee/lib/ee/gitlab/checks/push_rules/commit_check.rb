# frozen_string_literal: true

module EE
  module Gitlab
    module Checks
      module PushRules
        class CommitCheck < ::Gitlab::Checks::BaseSingleChecker
          ERROR_MESSAGES = {
            committer_not_verified: "Committer email '%{committer_email}' is not verified.",
            committer_not_allowed: "You cannot push commits for '%{committer_email}'. You can only push commits if the committer email is one of your own verified emails."
          }.freeze

          LOG_MESSAGE = "Checking if commits follow defined push rules..."

          def validate!
            return unless push_rule

            commit_validation = push_rule.commit_validation?
            # if newrev is blank, the branch was deleted
            return if deletion? || !commit_validation

            logger.log_timed(LOG_MESSAGE) do
              commits.each do |commit|
                logger.check_timeout_reached

                push_rule_commit_check(commit)
              end
            end
          rescue ::PushRule::MatchError => e
            raise ::Gitlab::GitAccess::ForbiddenError, e.message
          end

          private

          def push_rule_commit_check(commit)
            error = check_commit(commit)
            raise ::Gitlab::GitAccess::ForbiddenError, error if error
          end

          # If commit does not pass push rule validation the whole push should be rejected.
          # This method should return nil if no error found or a string if error.
          # In case of errors - all other checks will be canceled and push will be rejected.
          def check_commit(commit)
            unless push_rule.commit_message_allowed?(commit.safe_message)
              return "Commit message does not follow the pattern '#{push_rule.commit_message_regex}'"
            end

            if push_rule.commit_message_blocked?(commit.safe_message)
              return "Commit message contains the forbidden pattern '#{push_rule.commit_message_negative_regex}'"
            end

            unless push_rule.author_email_allowed?(commit.committer_email)
              return "Committer's email '#{commit.committer_email}' does not follow the pattern '#{push_rule.author_email_regex}'"
            end

            unless push_rule.author_email_allowed?(commit.author_email)
              return "Author's email '#{commit.author_email}' does not follow the pattern '#{push_rule.author_email_regex}'"
            end

            committer_error_message = committer_check(commit)
            return committer_error_message if committer_error_message

            unless push_rule.non_dco_commit_allowed?(commit.safe_message)
              return "Commit message must contain a DCO signoff"
            end

            if !updated_from_web? && !push_rule.commit_signature_allowed?(commit)
              return "Commit must be signed with a GPG key"
            end

            # Check whether author is a GitLab member
            if push_rule.member_check
              unless ::User.find_by_any_email(commit.author_email).present?
                return "Author '#{commit.author_email}' is not a member of team"
              end

              if commit.author_email.casecmp(commit.committer_email) == -1
                unless ::User.find_by_any_email(commit.committer_email).present?
                  return "Committer '#{commit.committer_email}' is not a member of team"
                end
              end
            end

            nil
          end

          def committer_check(commit)
            unless push_rule.committer_allowed?(commit.committer_email, user_access.user)
              # We can assume only one user holds an unconfirmed primary email address. Since we want
              # to give feedback whether this is an unconfirmed address, we look for any user that
              # matches by disabling the confirmation requirement.
              committer = commit.committer(confirmed: false)
              committer_is_current_user = committer == user_access.user

              if committer_is_current_user && !committer.verified_email?(commit.committer_email)
                return ERROR_MESSAGES[:committer_not_verified] % { committer_email: commit.committer_email }
              else
                return ERROR_MESSAGES[:committer_not_allowed] % { committer_email: commit.committer_email }
              end
            end

            if commit.committer_email == commit.author_email && !push_rule.committer_name_allowed?(commit.author_name, user_access.user)
              "Your git username is inconsistent with GitLab account name"
            end
          end
        end
      end
    end
  end
end
