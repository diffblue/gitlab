# frozen_string_literal: true

module ComplianceManagement
  module ComplianceReport
    class CommitLoader
      COMMITS_PER_PROJECT = 1024
      COMMIT_BATCH_SIZE = 100

      def initialize(group, current_user, filter_params = {})
        raise ArgumentError, 'The group is a required argument' if group.blank?
        raise ArgumentError, 'The user is a required argument' if current_user.blank?

        @current_user = current_user
        @group = group
        @filters = filter_params
        @count = 0
        @from = @filters[:from] || 1.month.ago
        @to = @filters[:to] || Time.current
      end

      attr_reader :count

      def find_each(&block)
        # find all MR related commits
        mr_commits = Hash.new { |h, k| h[k] = [] }
        merge_requests.find_each.each_with_object(mr_commits) do |mr, result|
          mr.commit_shas.each { |sha| result[sha] << mr }

          result[mr.squash_commit_sha] << mr if mr.squash_commit_sha?
          result[mr.merge_commit_sha] << mr if mr.merge_commit_sha?
        end

        # find all non-MR commits (e.g. a commit pushed directly to the project)
        projects.inc_routes.find_each do |project|
          commits_for_project = 0

          while commits_for_project < COMMITS_PER_PROJECT
            batch = batch_of_commits_for_project(project, commits_for_project, COMMIT_BATCH_SIZE)

            batch.each do |commit|
              mrs = mr_commits[commit.sha]

              if mrs.present?
                mrs.each do |mr|
                  yield CsvRow.new(commit, current_user, from, to, merge_request: mr)

                  commits_for_project += 1
                  @count += 1
                end
              else
                yield CsvRow.new(commit, current_user, from, to)

                commits_for_project += 1
                @count += 1
              end

              break if commits_for_project == COMMITS_PER_PROJECT
            end

            break if batch.count < COMMIT_BATCH_SIZE
          end
        end
      end

      private

      attr_reader :current_user, :group, :filters, :from, :to

      def merge_requests
        MergeRequestsFinder
          .new(current_user, merge_request_finder_options)
          .execute
          .preload_author
          .preload_approved_by_users
          .preload_target_project_with_namespace
          .preload_project_and_latest_diff
          .preload_metrics([:merged_by])
      end

      def merge_request_finder_options
        {
          group_id: group.id,
          state: 'merged',
          merge_commit_sha: filters[:commit_sha],
          include_subgroups: true
        }
      end

      def projects
        GroupProjectsFinder.new(
          group: group,
          current_user: current_user,
          options: { include_subgroups: true }
        ).execute
      end

      def batch_of_commits_for_project(project, offset, limit)
        if filters[:commit_sha].present?
          [
            project.repository.commit_by(oid: filters[:commit_sha])
          ].compact
        else
          project.repository.commits(
            nil,
            offset: offset,
            limit: limit,
            after: from,
            before: to
          )
        end
      rescue ::Gitlab::Git::Repository::NoRepository
        []
      end
    end
  end
end
