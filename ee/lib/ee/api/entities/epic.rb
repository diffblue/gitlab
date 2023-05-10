# frozen_string_literal: true

module EE
  module API
    module Entities
      class Epic < Grape::Entity
        include ::API::Helpers::RelatedResourcesHelpers

        expose :id, documentation: { type: "integer", example: 123 }
        expose :iid, documentation: { type: "integer", example: 123 }
        expose :color, documentation: { type: "string", example: "#1068bf" }
        expose :text_color, documentation: { type: "string", example: "#1068bf" }
        expose :group_id, documentation: { type: "integer", example: 17 }
        expose :parent_id, documentation: { type: "integer", example: 12 }
        expose :parent_iid, documentation: { type: "integer", example: 19 } do |epic|
          epic.parent.iid if epic.has_parent?
        end
        expose :title, documentation: { type: "string", example: "My Epic" }
        expose :description, documentation: { type: "string", example: "Epic description" }
        expose :confidential, documentation: { type: "boolean", example: false }
        expose :author, using: ::API::Entities::UserBasic
        expose :start_date, documentation: { type: "dateTime", example: "2022-01-31T15:10:45.080Z" }
        expose :start_date_is_fixed?,
          as: :start_date_is_fixed,
          documentation: { type: "boolean", example: true }
        expose :start_date_fixed,
          :start_date_from_inherited_source,
          documentation: { type: "dateTime", example: "2022-01-31T15:10:45.080Z" }
        expose :start_date_from_milestones, # @deprecated in favor of start_date_from_inherited_source
          documentation: { type: "dateTime", example: "2022-01-31T15:10:45.080Z" }
        expose :end_date, documentation: { type: "dateTime", example: "2022-01-31T15:10:45.080Z" } # @deprecated in favor of due_date
        expose :end_date, as: :due_date, documentation: { type: "dateTime", example: "2022-01-31T15:10:45.080Z" }
        expose :due_date_is_fixed?,
          as: :due_date_is_fixed,
          documentation: { type: "boolean", example: true }
        expose :due_date_fixed,
          :due_date_from_inherited_source,
          documentation: { type: "boolean", example: true }
        expose :due_date_from_milestones, # @deprecated in favor of due_date_from_inherited_source
          documentation: { type: "dateTime", example: "2022-01-31T15:10:45.080Z" }
        expose :state, documentation: { type: "string", example: "opened" }
        expose :web_edit_url, # @deprecated
          documentation: { type: "string", example: "http://gitlab.example.com/groups/test/-/epics/4/edit" }
        expose :web_url, documentation: { type: "string", example: "http://gitlab.example.com/groups/test/-/epics/4" }
        expose :references, documentation: { is_array: true }, with: ::API::Entities::IssuableReferences do |epic|
          epic
        end
        # reference is deprecated in favour of references
        # Introduced [Gitlab 12.6](https://gitlab.com/gitlab-org/gitlab/merge_requests/20354)
        expose :reference, if: { with_reference: true } do |epic|
          epic.to_reference(full: true)
        end
        expose :created_at, documentation: { type: "dateTime", example: "2022-01-31T15:10:45.080Z" }
        expose :updated_at, documentation: { type: "dateTime", example: "2022-01-31T15:10:45.080Z" }
        expose :closed_at, documentation: { type: "dateTime", example: "2022-01-31T15:10:45.080Z" }
        expose :labels, documentation: { is_array: true } do |epic, options|
          if options[:with_labels_details]
            ::API::Entities::LabelBasic.represent(epic.labels.sort_by(&:title))
          else
            epic.labels.map(&:title).sort
          end
        end
        expose :upvotes, documentation: { type: "integer", example: 4 } do |epic, options|
          if options[:issuable_metadata]
            # Avoids an N+1 query when metadata is included
            options[:issuable_metadata][epic.id].upvotes
          else
            epic.upvotes
          end
        end
        expose :downvotes, documentation: { type: "integer", example: 3 } do |epic, options|
          if options[:issuable_metadata]
            # Avoids an N+1 query when metadata is included
            options[:issuable_metadata][epic.id].downvotes
          else
            epic.downvotes
          end
        end

        # Calculating the value of subscribed field triggers Markdown
        # processing. We can't do that for multiple epics
        # requests in a single API request.
        expose :subscribed,
          documentation: { type: "boolean", example: true },
          if: -> (_, options) { options.fetch(:include_subscribed, false) } do |epic, options|
            user = options[:user]

            user.present? ? epic.subscribed?(user) : false
          end

        def web_url
          ::Gitlab::Routing.url_helpers.group_epic_url(object.group, object)
        end

        def web_edit_url
          ::Gitlab::Routing.url_helpers.group_epic_path(object.group, object)
        end

        expose :_links do
          expose :self,
            documentation: {
              type: "string",
              example: "http://gitlab.example.com/api/v4/groups/7/epics/5"
            } do |epic|
              expose_url(api_v4_groups_epics_path(id: epic.group_id, epic_iid: epic.iid))
            end

          expose :epic_issues,
            documentation: {
              type: "string",
              example: "http://gitlab.example.com/api/v4/groups/7/epics/5/issues"
            } do |epic|
              expose_url(api_v4_groups_epics_issues_path(id: epic.group_id, epic_iid: epic.iid))
            end

          expose :group,
            documentation: {
              type: "string",
              example: "http://gitlab.example.com/api/v4/groups/7"
            } do |epic|
              expose_url(api_v4_groups_path(id: epic.group_id))
            end

          expose :parent,
            documentation: {
              type: "string",
              example: "http://gitlab.example.com/api/v4/groups/7/epics/4"
            } do |epic|
              expose_url(api_v4_groups_epics_path(id: epic.parent.group_id, epic_iid: epic.parent.iid)) if epic.has_parent?
            end
        end
      end
    end
  end
end
