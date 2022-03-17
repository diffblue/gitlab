# frozen_string_literal: true

module EE
  module API
    module Entities
      class Epic < Grape::Entity
        include ::API::Helpers::RelatedResourcesHelpers

        can_admin_epic = ->(epic, opts) { Ability.allowed?(opts[:user], :admin_epic, epic) }

        expose :id
        expose :iid
        expose :color
        expose :text_color
        expose :group_id
        expose :parent_id
        expose :parent_iid do |epic|
          epic.parent.iid if epic.has_parent?
        end
        expose :title
        expose :description
        expose :confidential
        expose :author, using: ::API::Entities::UserBasic
        expose :start_date
        expose :start_date_is_fixed?, as: :start_date_is_fixed, if: can_admin_epic
        expose :start_date_fixed, :start_date_from_inherited_source, if: can_admin_epic
        expose :start_date_from_milestones, if: can_admin_epic # @deprecated in favor of start_date_from_inherited_source
        expose :end_date # @deprecated in favor of due_date
        expose :end_date, as: :due_date
        expose :due_date_is_fixed?, as: :due_date_is_fixed, if: can_admin_epic
        expose :due_date_fixed, :due_date_from_inherited_source, if: can_admin_epic
        expose :due_date_from_milestones, if: can_admin_epic # @deprecated in favor of due_date_from_inherited_source
        expose :state
        expose :web_edit_url, if: can_admin_epic # @deprecated
        expose :web_url
        expose :references, with: ::API::Entities::IssuableReferences do |epic|
          epic
        end
        # reference is deprecated in favour of references
        # Introduced [Gitlab 12.6](https://gitlab.com/gitlab-org/gitlab/merge_requests/20354)
        expose :reference, if: { with_reference: true } do |epic|
          epic.to_reference(full: true)
        end
        expose :created_at
        expose :updated_at
        expose :closed_at
        expose :labels do |epic, options|
          if options[:with_labels_details]
            ::API::Entities::LabelBasic.represent(epic.labels.sort_by(&:title))
          else
            epic.labels.map(&:title).sort
          end
        end
        expose :upvotes do |epic, options|
          if options[:issuable_metadata]
            # Avoids an N+1 query when metadata is included
            options[:issuable_metadata][epic.id].upvotes
          else
            epic.upvotes
          end
        end
        expose :downvotes do |epic, options|
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
        expose :subscribed, if: -> (_, options) { options.fetch(:include_subscribed, false) } do |epic, options|
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
          expose :self do |epic|
            expose_url(api_v4_groups_epics_path(id: epic.group_id, epic_iid: epic.iid))
          end

          expose :epic_issues do |epic|
            expose_url(api_v4_groups_epics_issues_path(id: epic.group_id, epic_iid: epic.iid))
          end

          expose :group do |epic|
            expose_url(api_v4_groups_path(id: epic.group_id))
          end

          expose :parent do |epic|
            expose_url(api_v4_groups_epics_path(id: epic.parent.group_id, epic_iid: epic.parent.iid)) if epic.has_parent?
          end
        end
      end
    end
  end
end
