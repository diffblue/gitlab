# frozen_string_literal: true

module Gitlab
  module Analytics
    module TypeOfWork
      class TasksByType
        LabelCountResult = Struct.new(:label, :series)

        FINDER_CLASSES = {
          MergeRequest.to_s => MergeRequestsFinder,
          Issue.to_s => IssuesFinder
        }.freeze

        TOP_LABELS_COUNT = 10

        def initialize(group:, params:, current_user:)
          @group = group
          @params = params
          @current_user = current_user
          @finder = finder_class.new(current_user, finder_params)
        end

        def counts_by_labels
          format_result(query_result)
        end

        # top N commonly used labels for Issues or MergeRequests ordered by usage
        # rubocop: disable CodeReuse/ActiveRecord
        def top_labels(limit = TOP_LABELS_COUNT)
          targets = finder
            .execute
            .order_by(:id_desc)
            .limit(100)

          GroupLabel
            .top_labels_by_target(targets)
            .limit(limit)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        private

        attr_reader :group, :params, :finder, :current_user

        def finder_class
          FINDER_CLASSES.fetch(params[:subject], FINDER_CLASSES.each_value.first)
        end

        def format_result(result)
          result.each_with_object({}) do |((label_id, date), count), hash|
            label = labels_by_id.fetch(label_id)

            hash[label_id] ||= LabelCountResult.new(label, [])
            hash[label_id].series << [date, count]
          end.values
        end

        def finder_params
          {
            include_subgroups: true,
            group_id: group.id
          }.merge(params.slice(:created_after, :created_before, :author_username, :milestone_title, :assignee_username))
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def query_result
          finder
            .execute
            .joins(:label_links)
            .where(filters)
            .group(label_id_column, date_column)
            .reorder(nil)
            .count(subject_table[:id])
        end

        def filters
          {}.tap do |hash|
            hash[:label_links] = { label_id: labels_by_id.keys }
            hash[:project_id] = params[:project_ids] unless params[:project_ids].blank?
          end
        end

        def labels
          return [] if params[:label_names].blank?

          @labels ||= LabelsFinder.new(current_user, {
                                         group_id: group.id,
                                         include_ancestor_groups: true,
                                         only_group_labels: true,
                                         title: params[:label_names]
                                       }).execute
        end

        # rubocop: enable CodeReuse/ActiveRecord

        def label_id_column
          LabelLink.arel_table[:label_id]
        end

        # Generating `DATE(created_at)` string
        def date_column
          Arel::Nodes::NamedFunction.new('DATE', [subject_table[:created_at]]).to_sql
        end

        def subject_table
          finder.klass.arel_table
        end

        def labels_by_id
          @labels_by_id = labels.index_by(&:id)
        end
      end
    end
  end
end
