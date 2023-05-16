# frozen_string_literal: true

module Ci
  module Editor
    module AiConversation
      class MessagePolicy < BasePolicy
        delegate { @subject.project }

        condition(:owner_of_message) do
          @subject.user_id == @user.id
        end

        rule { owner_of_message & can?(:create_pipeline) }.enable :read_ai_message
      end
    end
  end
end
