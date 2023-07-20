# frozen_string_literal: true

module Elastic
  module Latest
    class IssueClassProxy < ApplicationClassProxy
      extend ::Gitlab::Utils::Override
      include StateFilter

      AGGREGATION_LIMIT = 500

      def elastic_search(query, options: {})
        query_hash = issue_query(query, options: options.merge(features: 'issues', no_join_project: true))

        search(query_hash, options)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def preload_indexing_data(relation)
        relation.includes(:author, :issue_assignees, :labels, project: [:project_feature, :namespace])
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def issue_aggregations(query, options)
        return [] if ::Feature.disabled?(:search_issue_label_aggregation, options[:current_user])

        query_hash = issue_query(query, options: options.merge(features: 'issues', no_join_project: true, aggregation: true))

        results = search(query_hash, options)

        ::Gitlab::Search::AggregationParser.call(results.response.aggregations)
      end

      private

      def issue_query(query, options:)
        query_hash =
          if query =~ /#(\d+)\z/
            iid_query_hash(Regexp.last_match(1))
          else
            # iid field can be added here as lenient option will
            # pardon format errors, like integer out of range.
            fields = %w[iid^3 title^2 description]
            basic_query_hash(fields, query, options)
          end

        context.name(:issue) do
          query_hash = context.name(:authorized) { authorization_filter(query_hash, options.merge(traversal_ids_prefix: :namespace_ancestry_ids)) }
          query_hash = context.name(:confidentiality) { confidentiality_filter(query_hash, options) }
          query_hash = context.name(:match) { state_filter(query_hash, options) }
          query_hash = context.name(:filter) { label_ids_filter(query_hash, options) }
          unless options[:current_user]&.can_admin_all_resources?
            query_hash = context.name(:hidden) { hidden_filter(query_hash) }
          end

          if Feature.enabled?(:search_issues_hide_archived_projects) && ::Elastic::DataMigrationService.migration_has_finished?(:backfill_archived_on_work_items)
            query_hash = context.name(:archived) { archived_filter(query_hash) } unless options[:include_archived]
          end
        end

        return apply_aggregation(query_hash) if options[:aggregation]

        apply_sort(query_hash, options)
      end

      def apply_aggregation(query_hash)
        query_hash.merge(size: 0,
          aggs: {
            labels: {
              terms: {
                field: 'label_ids',
                size: AGGREGATION_LIMIT
              }
            }
          }
        )
      end

      override :apply_sort
      def apply_sort(query_hash, options)
        case ::Gitlab::Search::SortOptions.sort_and_direction(options[:order_by], options[:sort])
        when :popularity_asc
          query_hash.merge(sort: {
            upvotes: {
              order: 'asc'
            }
          })
        when :popularity_desc
          query_hash.merge(sort: {
            upvotes: {
              order: 'desc'
            }
          })
        else
          super
        end
      end

      # Builds an elasticsearch query that will select documents from a
      # set of projects for Group and Project searches, taking user access
      # rules for issues into account. Relies upon super for Global searches
      override :project_ids_filter
      def project_ids_filter(query_hash, options)
        return super if options[:public_and_internal_projects]

        current_user = options[:current_user]
        scoped_project_ids = scoped_project_ids(current_user, options[:project_ids])
        return super if scoped_project_ids == :any

        get_query_hash_for_project_and_group_searches(scoped_project_ids, current_user, query_hash, options[:features])
      end

      def confidentiality_filter(query_hash, options)
        current_user = options[:current_user]
        project_ids = options[:project_ids]

        if [true, false].include?(options[:confidential])
          query_hash[:query][:bool][:filter] << { term: { confidential: options[:confidential] } }
        end

        return query_hash if current_user&.can_read_all_resources?

        scoped_project_ids = scoped_project_ids(current_user, project_ids)
        authorized_project_ids = authorized_project_ids(current_user, options)

        # we can shortcut the filter if the user is authorized to see
        # all the projects for which this query is scoped on
        unless scoped_project_ids == :any || scoped_project_ids.empty?
          return query_hash if authorized_project_ids.to_set == scoped_project_ids.to_set
        end

        filter = { term: { confidential: { _name: context.name(:non_confidential), value: false } } }

        if current_user
          filter = {
              bool: {
                should: [
                  { term: { confidential: { _name: context.name(:non_confidential), value: false } } },
                  {
                    bool: {
                      must: [
                        { term: { confidential: true } },
                        {
                          bool: {
                            should: [
                              { term: { author_id: { _name: context.name(:as_author), value: current_user.id } } },
                              { term: { assignee_id: { _name: context.name(:as_assignee), value: current_user.id } } },
                              { terms: { _name: context.name(:project, :membership, :id), project_id: authorized_project_ids } }
                            ]
                          }
                        }
                      ]
                    }
                  }
                ]
              }
            }
        end

        query_hash[:query][:bool][:filter] << filter
        query_hash
      end

      def hidden_filter(query_hash)
        query_hash[:query][:bool][:filter] << { term: { hidden: { _name: context.name(:non_hidden), value: false } } }
        query_hash
      end

      def label_ids_filter(query_hash, options)
        labels = [options[:labels]].flatten
        return query_hash unless labels.any?
        return query_hash if options[:count_only] || options[:aggregation]

        query_hash[:query][:bool][:filter] ||= []
        query_hash[:query][:bool][:filter] << {
          terms_set: {
            label_ids: {
              _name: context.name(:label_ids),
              terms: labels,
              minimum_should_match_script: {
                source: 'params.num_terms'
              }
            }
          }
        }
        query_hash
      end
    end
  end
end
