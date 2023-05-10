# frozen_string_literal: true

module Ci
  module Editor
    module AiConversation
      class Message < Ci::ApplicationRecord
        include EachBatch

        self.table_name = 'ci_editor_ai_conversation_messages'

        belongs_to :project
        belongs_to :user

        scope :belonging_to, ->(project, user) { where(project: project, user: user) }
        scope :asc, -> { order(created_at: :asc) }
        scope :desc, -> { order(created_at: :desc) }
        scope :first_pair, ->(project, user) { belonging_to(project, user).asc.limit(2) }

        def fetching?
          return false if [Gitlab::Llm::OpenAi::Options::DEFAULT_ROLE,
            Gitlab::Llm::OpenAi::Options::SYSTEM_ROLE].include?(role)

          return true if role == Gitlab::Llm::OpenAi::Options::AI_ROLE && async_errors.empty? && !content

          false
        end
      end
    end
  end
end
