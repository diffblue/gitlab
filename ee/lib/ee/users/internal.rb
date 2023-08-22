# frozen_string_literal: true

module EE
  module Users
    module Internal
      extend ActiveSupport::Concern

      class_methods do
        # rubocop:disable CodeReuse/ActiveRecord
        def visual_review_bot
          email_pattern = "visual_review%s@#{Settings.gitlab.host}"

          unique_internal(::User.where(user_type: :visual_review_bot), 'visual-review-bot', email_pattern) do |u|
            u.bio = 'The Gitlab Visual Review feedback bot'
            u.name = 'Gitlab Visual Review Bot'
          end
        end

        def suggested_reviewers_bot
          email_pattern = "suggested-reviewers-bot%s@#{Settings.gitlab.host}"

          unique_internal(
            ::User.where(user_type: :suggested_reviewers_bot), 'suggested-reviewers-bot', email_pattern) do |u|
            u.bio = 'The GitLab suggested reviewers bot used for suggested reviewers'
            u.name = 'GitLab Suggested Reviewers Bot'
          end
        end
        # rubocop:enable CodeReuse/ActiveRecord
      end
    end
  end
end
