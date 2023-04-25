# frozen_string_literal: true

# rubocop: disable CodeReuse/ActiveRecord

module Gitlab
  module ContributionAnalytics
    class DataCollector
      EVENT_TYPES = %i[push issues_created issues_closed merge_requests_closed merge_requests_created merge_requests_merged merge_requests_approved total_events].freeze

      attr_reader :group, :from, :to

      def initialize(group:, from: 1.week.ago.to_date, to: Date.current)
        @group = group
        @from = from.beginning_of_day
        @to = to.end_of_day
      end

      def push_by_author_count
        all_counts.each_with_object({}) do |(event, count), hash|
          hash[event.author_id] = count if event.target_type.nil? && event.pushed_action?
        end
      end

      def issues_created_by_author_count
        all_counts.each_with_object({}) do |(event, count), hash|
          hash[event.author_id] = count if event.issue? && event.created_action?
        end
      end

      def issues_closed_by_author_count
        all_counts.each_with_object({}) do |(event, count), hash|
          hash[event.author_id] = count if event.issue? && event.closed_action?
        end
      end

      def merge_requests_closed_by_author_count
        all_counts.each_with_object({}) do |(event, count), hash|
          hash[event.author_id] = count if event.merge_request? && event.closed_action?
        end
      end

      def merge_requests_created_by_author_count
        all_counts.each_with_object({}) do |(event, count), hash|
          hash[event.author_id] = count if event.merge_request? && event.created_action?
        end
      end

      def merge_requests_merged_by_author_count
        all_counts.each_with_object({}) do |(event, count), hash|
          hash[event.author_id] = count if event.merge_request? && event.merged_action?
        end
      end

      def merge_requests_approved_by_author_count
        all_counts.each_with_object({}) do |(event, count), hash|
          hash[event.author_id] = count if event.merge_request? && event.approved_action?
        end
      end

      def total_events_by_author_count
        all_counts.each_with_object({}) do |(event, count), hash|
          hash[event.author_id] ||= 0
          hash[event.author_id] += count
        end
      end

      def users
        @users ||= User
          .select(:id, :name, :username)
          .where(id: total_events_by_author_count.keys)
          .reorder(:id)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def totals
        @totals ||= {
          push: push_by_author_count,
          issues_created: issues_created_by_author_count,
          issues_closed: issues_closed_by_author_count,
          merge_requests_closed: merge_requests_closed_by_author_count,
          merge_requests_created: merge_requests_created_by_author_count,
          merge_requests_merged: merge_requests_merged_by_author_count,
          merge_requests_approved: merge_requests_approved_by_author_count,
          total_events: total_events_by_author_count
        }
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def base_query
        cte = Gitlab::SQL::CTE.new(:project_ids,
          ::Route
            .where(source_type: 'Project')
            .where(::Route.arel_table[:path].matches("#{::Route.sanitize_sql_like(group.full_path)}/%", nil, true))
            .select('source_id AS id'))
        cte_condition = 'project_id IN (SELECT id FROM project_ids)'

        events_from_date = ::Event
          .where(cte_condition)
          .where(Event.arel_table[:created_at].gteq(from))
          .where(Event.arel_table[:created_at].lteq(to))

        ::Event.with(cte.to_arel).from_union(
          [
            events_from_date.where(action: :pushed, target_type: nil),
            events_from_date.where(
              action: [:created, :closed, :merged, :approved],
              target_type: [::MergeRequest.name, ::Issue.name])
          ], remove_duplicates: false)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      def all_counts
        @all_counts ||= raw_counts.transform_keys do |author_id, target_type, action|
          Event.new(author_id: author_id, target_type: target_type, action: action).tap do |event|
            event.readonly!
          end
        end
      end

      # Format:
      # {
      #   [user1_id, target_type, action] => count,
      #   [user2_id, target_type, action] => count
      # }
      def raw_counts
        Rails.cache.fetch(cache_key, expires_in: 1.minute) do
          base_query.totals_by_author_target_type_action
        end
      end

      def cache_key
        [group, from, to]
      end
    end
  end
end
