# frozen_string_literal: true

module Mutations
  module WorkItems
    # TODO: Deprecate in favor of using WorkItemUpdate. See https://gitlab.com/gitlab-org/gitlab/-/issues/366300
    class UpdateWidgets < BaseMutation
      graphql_name 'WorkItemUpdateWidgets'
      description "Updates the attributes of a work item's widgets by global ID." \
                  " Available only when feature flag `work_items` is enabled."

      include Mutations::SpamProtection

      authorize :update_work_item

      argument :id, ::Types::GlobalIDType[::WorkItem],
               required: true,
               description: 'Global ID of the work item.'

      ::WorkItems::Type.available_widgets.each do |widget_class|
        input_type_class = begin
          "::Types::WorkItems::Widgets::#{widget_class.type.to_s.titleize}InputType".constantize
        rescue NameError
          nil
        end

        next unless input_type_class

        argument widget_class.api_symbol, input_type_class,
                 required: false,
                 description: "Input for #{widget_class.type} widget."
      end

      field :work_item, Types::WorkItemType,
            null: true,
            description: 'Updated work item.'

      def resolve(id:, **widget_attributes)
        work_item = authorized_find!(id: id)

        unless work_item.project.work_items_feature_flag_enabled?
          return { errors: ['`work_items` feature flag disabled for this project'] }
        end

        spam_params = ::Spam::SpamParams.new_from_request(request: context[:request])

        ::WorkItems::UpdateService.new(
          project: work_item.project,
          current_user: current_user,
          # Cannot use prepare to use `.to_h` on each input due to
          # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/87472#note_945199865
          widget_params: widget_attributes.transform_values { |values| values.to_h },
          spam_params: spam_params
        ).execute(work_item)

        check_spam_action_response!(work_item)

        {
          work_item: work_item.valid? ? work_item : nil,
          errors: errors_on_object(work_item)
        }
      end

      private

      def find_object(id:)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
