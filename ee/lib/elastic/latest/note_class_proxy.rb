# frozen_string_literal: true

module Elastic
  module Latest
    class NoteClassProxy < ApplicationClassProxy
      extend ::Gitlab::Utils::Override

      def es_type
        'note'
      end

      def elastic_search(query, options: {})
        options[:in] = ['note']
        options[:no_join_project] = true

        query_hash = basic_query_hash(%w[note], query, options)

        context.name(:note) do
          query_hash = context.name(:authorized) { project_ids_filter(query_hash, options) }
          query_hash = context.name(:confidentiality) { confidentiality_filter(query_hash, options) }
        end

        query_hash[:highlight] = highlight_options(options[:in]) unless options[:count_only]

        search(query_hash, options)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def preload_indexing_data(relation)
        relation.includes(noteable: :assignees, project: [:project_feature, :route])
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      def confidentiality_filter(query_hash, options)
        current_user = options[:current_user]

        return query_hash if current_user&.can_read_all_resources?

        filter = {
          bool: {
            should: [
              bool: {
                must: [
                  {
                    bool: {
                      _name: context.name(:issue, :not_confidential),
                      should: [
                        { bool: { must_not: [{ exists: { field: :issue } }] } },
                        { term: { "issue.confidential" => false } }
                      ]
                    }
                  },
                  {
                    bool: {
                      _name: context.name(:not_confidential),
                      should: [
                        { bool: { must_not: [{ exists: { field: :confidential } }] } },
                        { term: { confidential: false } }
                      ]
                    }
                  }
                ]
              }
            ]
          }
        }

        if current_user
          filter[:bool][:should] << {
            bool: {
              must: [
                {
                  bool: {
                    should: [
                      { term: { "issue.confidential" => { _name: context.name(:issue, :confidential), value: true } } },
                      { term: { confidential: { _name: context.name(:confidential), value: true } } }
                    ]
                  }
                },
                {
                  bool: {
                    should: [
                      { term: { "issue.author_id" => { _name: context.name(:as_author), value: current_user.id } } },
                      { term: { "issue.assignee_id" => { _name: context.name(:as_assignee), value: current_user.id } } },
                      { terms: { _name: context.name(:project, :membership, :id), project_id: authorized_project_ids(current_user, options) } }
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

      def noteable_type_to_feature
        {
          'Issue': :issues,
          'MergeRequest': :merge_requests,
          'Snippet': :snippets,
          'Commit': :repository
        }
      end

      override :project_ids_filter
      def project_ids_filter(query_hash, options)
        # support for not using project joins in the query
        no_join_project = options[:no_join_project]

        query_hash[:query][:bool][:filter] ||= []

        project_query = context.name(:project) do
          project_ids_query(
            options[:current_user],
            options[:project_ids],
            options[:public_and_internal_projects],
            options[:features],
            no_join_project
          )
        end

        filters = {
          bool: {
            _name: context.name,
            should: []
          }
        }

        # For each project id filter,
        # extract the noteable_type attribute,
        # and use that to filter at Note level.
        project_query[:should].flatten.each do |condition|
          noteable_type = condition.delete(:noteable_type).to_s

          should_filter = {
            bool: {
              must: [
                { term: { noteable_type: { _name: context.name(:noteable, :is_a, noteable_type), value: noteable_type } } }
              ]
            }
          }

          should_filter[:bool][:must] << if no_join_project
                                           condition
                                         else
                                           {
                                             has_parent: {
                                               parent_type: "project",
                                               query: {
                                                 bool: {
                                                   should: condition
                                                 }
                                               }
                                             }
                                           }
                                         end

          filters[:bool][:should] << should_filter
        end

        query_hash[:query][:bool][:filter] << filters
        query_hash
      end

      # Query notes based on the various feature permission of the noteable_type.
      # Appends `noteable_type` (which will be removed in project_ids_filter)
      # for base model filtering.
      override :pick_projects_by_membership
      def pick_projects_by_membership(project_ids, user, no_join_project, _ = nil)
        # support for not using project joins in the query
        project_id_key = no_join_project ? :project_id : :id

        noteable_type_to_feature.map do |noteable_type, feature|
          context.name(feature) do
            condition =
              if project_ids == :any
                { term: { visibility_level: { _name: context.name(:any), value: Project::PRIVATE } } }
              else
                { terms: { _name: context.name(:membership, :id), project_id_key => filter_ids_by_feature(project_ids, user, feature) } }
              end

            limit =
              { terms: { _name: context.name(:enabled_or_private), "#{feature}_access_level" => [::ProjectFeature::ENABLED, ::ProjectFeature::PRIVATE] } }

            { bool: { _name: context.name, filter: [condition, limit] }, noteable_type: noteable_type }
          end
        end
      end

      # Query notes based on the various feature permission of the noteable_type.
      # Appends `noteable_type` (which will be removed in project_ids_filter)
      # for base model filtering.
      override :limit_by_feature
      def limit_by_feature(condition, _ = nil, include_members_only:)
        noteable_type_to_feature.map do |noteable_type, feature|
          context.name(feature) do
            limit =
              if include_members_only
                { terms: { _name: context.name(:enabled_or_private), "#{feature}_access_level" => [::ProjectFeature::ENABLED, ::ProjectFeature::PRIVATE] } }
              else
                { term: { "#{feature}_access_level" => { _name: context.name(:enabled), value: ::ProjectFeature::ENABLED } } }
              end

            { bool: { _name: context.name, filter: [condition, limit] }, noteable_type: noteable_type }
          end
        end
      end
    end
  end
end
