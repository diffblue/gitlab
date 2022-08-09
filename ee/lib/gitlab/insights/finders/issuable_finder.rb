# frozen_string_literal: true

module Gitlab
  module Insights
    module Finders
      class IssuableFinder
        include Gitlab::Utils::StrongMemoize

        IssuableFinderError = Class.new(StandardError)
        InvalidIssuableTypeError = Class.new(IssuableFinderError)
        InvalidGroupByError = Class.new(IssuableFinderError)
        InvalidPeriodLimitError = Class.new(IssuableFinderError)
        InvalidEntityError = Class.new(IssuableFinderError)

        FINDERS = {
          issue: ::IssuesFinder,
          merge_request: ::MergeRequestsFinder
        }.with_indifferent_access.freeze
        PERIOD_FIELDS = {
          issue: { opened: :created_at, closed: :closed_at },
          merge_request: { opened: :created_at, merged: :merged_at }
        }.with_indifferent_access.freeze
        PERIODS = {
          days: { default: 30 },
          weeks: { default: 12 },
          months: { default: 12 }
        }.with_indifferent_access.freeze

        def initialize(entity, current_user, query: {}, projects: {})
          @entity = entity
          @current_user = current_user
          @query = query
          @projects = projects
        end

        def issuable_type
          @issuable_type ||= query[:issuable_type]&.to_s&.singularize&.to_sym
        end

        def issuable_state
          @issuable_state ||= query[:issuable_state]&.to_s&.to_sym || :opened
        end

        def period_field
          @period_field ||= PERIOD_FIELDS.dig(issuable_type, issuable_state) || :created_at
        end

        # Returns an Active Record relation of issuables.
        def find
          return unless entity_args

          relation = finder
            .new(current_user, finder_args)
            .execute
          relation = relation.including_metrics if period_field == :merged_at
          relation = relation.preload(:labels) if query.key?(:collection_labels) # rubocop:disable CodeReuse/ActiveRecord

          relation
        end

        def period_limit
          @period_limit ||=
            if query.key?(:period_limit)
              begin
                Integer(query[:period_limit])
              rescue ArgumentError
                raise InvalidPeriodLimitError, "Invalid `:period_limit` option: `#{query[:period_limit]}`. Expected an integer!"
              end
            else
              PERIODS.dig(period, :default)
            end
        end

        private

        attr_reader :entity, :current_user, :query, :projects

        def finder
          FINDERS[issuable_type] ||
            raise(InvalidIssuableTypeError, "Invalid `:issuable_type` option: `#{query[:issuable_type]}`. Allowed values are #{FINDERS.keys}!")
        end

        def finder_args
          {
            include_subgroups: true,
            state: issuable_state,
            label_name: query[:filter_labels],
            sort: 'created_asc',
            created_after: created_after_argument
          }.merge(entity_args)
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def entity_args
          strong_memoize(:entity_args) do
            case entity
            when ::Project
              if found_projects
                if found_projects.exists?(entity.id)
                  { project_id: entity.id }
                else
                  { projects: ::Project.none }
                end
              else
                { project_id: entity.id }
              end
            when ::Namespace
              { group_id: entity.id, projects: found_projects }
            else
              raise InvalidEntityError, "Entity class `#{entity.class}` is not supported. Supported classes are Project and Namespace!"
            end
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def created_after_argument
          return unless query.key?(:group_by)

          Time.zone.now.advance(period => -period_limit)
        end

        def period
          @period ||=
            if query.key?(:group_by)
              period = query[:group_by].to_s.pluralize.to_sym

              unless PERIODS.key?(period)
                raise InvalidGroupByError, "Invalid `:group_by` option: `#{query[:group_by]}`. Allowed values are #{PERIODS.keys}!"
              end

              period
            else
              :days
            end
        end

        def found_projects
          @found_projects ||= ProjectsFinder.new(projects).execute
        end
      end
    end
  end
end
