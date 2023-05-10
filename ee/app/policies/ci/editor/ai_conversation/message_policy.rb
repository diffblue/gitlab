# frozen_string_literal: true

module Ci
  module Editor
    module AiConversation
      class MessagePolicy < BasePolicy
        delegate { @subject.project }

        condition(:owner_of_message) do
          @subject.user_id == @user.id
        end

        condition(:can_read_project) do
          can?(:read_project, @subject.project)
        end

        rule { owner_of_message & can_read_project }.enable :read_ai_message
      end
    end
  end
end
