# frozen_string_literal: true

module Ai
  module Project
    class Conversations
      def initialize(project, user)
        @project = project
        @user = user
      end

      def ci_config_messages
        Ci::Editor::AiConversation::Message.belonging_to(@project, @user).asc
      end
    end
  end
end
