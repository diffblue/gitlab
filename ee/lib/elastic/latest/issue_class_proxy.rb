# frozen_string_literal: true

module Elastic
  module Latest
    class IssueClassProxy < ApplicationClassProxy
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
          query_hash = context.name(:authorized) { authorization_filter(query_hash, options) }
          query_hash = context.name(:confidentiality) { confidentiality_filter(query_hash, options) }
          query_hash = context.name(:match) { state_filter(query_hash, options) }
          unless options[:current_user]&.can_admin_all_resources?
            query_hash = context.name(:hidden) { hidden_filter(query_hash) }
          end
        end

        if options[:aggregation]
          query_hash[:size] = 0
          query_hash[:aggs] = {
            labels: {
              terms: {
                field: 'label_ids',
                size: AGGREGATION_LIMIT
              }
            }
          }
        else
          query_hash = apply_sort(query_hash, options)
        end

        query_hash
      end

      # override
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

      def should_use_project_ids_filter?(options)
        options[:project_ids] == :any || options[:group_ids].blank?
      end

      def authorization_filter(query_hash, options)
        return project_ids_filter(query_hash, options) if should_use_project_ids_filter?(options)

        current_user = options[:current_user]
        namespaces = Namespace.find(authorized_namespace_ids(current_user, options))
        namespace_ancestry = namespaces.map(&:elastic_namespace_ancestry)

        return project_ids_filter(query_hash, options) if namespace_ancestry.blank?

        context.name(:reject_projects) do
          query_hash[:query][:bool][:must_not] ||= []
          query_hash[:query][:bool][:must_not] << rejected_project_filter(namespaces, options)
        end

        context.name(:namespace) do
          query_hash[:query][:bool][:filter] ||= []
          query_hash[:query][:bool][:filter] << ancestry_filter(current_user, namespace_ancestry, prefix: :namespace_ancestry_ids)
        end

        query_hash
      end

      def rejected_project_filter(namespaces, options)
        current_user = options[:current_user]
        scoped_project_ids = scoped_project_ids(current_user, options[:project_ids])
        return {} if scoped_project_ids == :any

        project_ids = filter_ids_by_feature(scoped_project_ids, current_user, 'issues')
        rejected_ids = namespaces.map do |namespace|
          namespace.all_project_ids_except(project_ids)
        end.flatten

        {
          terms: {
            _name: context.name,
            project_id: rejected_ids
          }
        }
      end

      # Builds an elasticsearch query that will select documents from a
      # set of projects for Group and Project searches, taking user access
      # rules for issues into account. Relies upon super for Global searches
      def project_ids_filter(query_hash, options)
        return super if options[:public_and_internal_projects]

        current_user = options[:current_user]
        scoped_project_ids = scoped_project_ids(current_user, options[:project_ids])
        return super if scoped_project_ids == :any

        context.name(:project) do
          query_hash[:query][:bool][:filter] ||= []
          query_hash[:query][:bool][:filter] << {
            terms: {
              _name: context.name,
              project_id: filter_ids_by_feature(scoped_project_ids, current_user, 'issues')
            }
          }
        end

        query_hash
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
    end
  end
end
