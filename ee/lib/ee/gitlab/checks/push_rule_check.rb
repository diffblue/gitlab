# frozen_string_literal: true

module EE
  module Gitlab
    module Checks
      class PushRuleCheck < ::Gitlab::Checks::BaseBulkChecker
        def validate!
          return unless push_rule

          if ::Feature.enabled?(:parallel_push_checks, project, type: :ops)
            run_checks_in_parallel!
          else
            run_checks_in_sequence!
          end
        end

        private

        # @return [Nil] returns nil unless an error is raised
        # @raise [Gitlab::GitAccess::ForbiddenError] if check fails
        def check_tag_or_branch!
          changes_access.single_change_accesses.each do |single_change_access|
            if single_change_access.tag_ref?
              PushRules::TagCheck.new(single_change_access).validate!
            elsif single_change_access.branch_ref?
              PushRules::BranchCheck.new(single_change_access).validate!
            end
          end

          nil
        end

        # @return [Nil] returns nil unless an error is raised
        # @raise [Gitlab::GitAccess::ForbiddenError] if check fails
        def check_file_size!
          PushRules::FileSizeCheck.new(changes_access).validate!

          nil
        end

        # Run the checks one after the other.
        #
        # @return [Nil] returns nil unless an error is raised
        # @raise [Gitlab::GitAccess::ForbiddenError] if any check fails
        def run_checks_in_sequence!
          check_tag_or_branch!
          check_file_size!
        end

        # Run the checks in separate threads for performance benefits.
        #
        # The git hook environment is currently set in the current thread
        # in lib/api/internal/base.rb. This needs to be passed into the
        # child threads we spawn here.
        #
        # @return [Nil] returns nil unless an error is raised
        # @raise [Gitlab::GitAccess::ForbiddenError] if any check fails
        def run_checks_in_parallel!
          git_env = ::Gitlab::Git::HookEnv.all(project.repository.gl_repository)
          @threads = []

          parallelize(git_env) do
            check_tag_or_branch!
          end

          parallelize(git_env) do
            check_file_size!
          end

          # Block whilst waiting for threads, however if one errors
          # it will exit early and raise the error immediately as
          # we set `abort_on_exception` to true.
          @threads.each(&:join)

          nil
        ensure
          # We want to make sure no threads are left dangling.
          # Threads can exit early when an exception is raised
          # and so we want to ensure any still running are exited
          # as soon as possible.
          @threads.each(&:exit)
        end

        # Runs a block inside a new thread. This thread will
        # exit immediately upon an exception being raised.
        #
        # @param git_env [Hash] the current git environment
        # @raise [Gitlab::GitAccess::ForbiddenError]
        def parallelize(git_env)
          @threads << Thread.new do
            Thread.current.tap do |t|
              t.name = "push_rule_check"
              t.abort_on_exception = true
              t.report_on_exception = false
            end

            ::Gitlab::WithRequestStore.with_request_store do
              ::Gitlab::Git::HookEnv.set(project.repository.gl_repository, git_env)

              yield
            end
          ensure
            ApplicationRecord.clear_active_connections!
          end
        end
      end
    end
  end
end
