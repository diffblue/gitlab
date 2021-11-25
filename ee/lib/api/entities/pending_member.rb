# frozen_string_literal: true

module API
  module Entities
    class PendingMember < Grape::Entity
      expose :id
      expose :user_name, as: :name, if: -> (_) { user.present? }
      expose :user_username, as: :username, if: -> (_) { user.present? }
      expose :email
      expose :web_url, if: -> (_) { user.present? }
      expose :invite?, as: :invited

      expose :avatar_url do |_|
        user&.avatar_url || GravatarService.new.execute(email)
      end

      expose :approved do |member|
        member.active?
      end

      def email
        object.invite_email || object.user.email
      end

      def web_url
        Gitlab::Routing.url_helpers.user_url(user)
      end

      def user
        object.user
      end
    end
  end
end
