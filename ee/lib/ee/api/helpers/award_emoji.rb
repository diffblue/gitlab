# frozen_string_literal: true

module EE
  module API
    module Helpers
      module AwardEmoji
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        class_methods do
          extend ::Gitlab::Utils::Override

          override :awardables
          def awardables
            super.concat([
                           { type: 'epic', resource: :groups, find_by: :iid, feature_category: :portfolio_management }
                         ])
          end

          override :awardable_id_desc
          def awardable_id_desc
            "The ID of an Issue, Merge Request, Epic or Snippet"
          end
        end

        # rubocop: disable CodeReuse/ActiveRecord
        override :awardable
        def awardable
          super

          @awardable ||= # rubocop:disable Gitlab/ModuleWithInstanceVariables
            if params.include?(:epic_iid)
              user_group.epics.find_by!(iid: params[:epic_iid])
            end
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
