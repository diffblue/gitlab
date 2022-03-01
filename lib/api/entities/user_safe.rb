# frozen_string_literal: true

module API
  module Entities
    class UserSafe < Grape::Entity
      include UsersHelper

      expose :id, :username
      expose :name do |user|
        next user.name unless user.project_bot?

        secure_project_bot_name(options[:current_user], user)
      end
    end
  end
end
