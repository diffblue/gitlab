# frozen_string_literal: true

module EE
  module API
    module Integrations
      extend ActiveSupport::Concern

      prepended do
        desc "Trigger a global slack command" do
          detail 'Added in GitLab 9.4'
          failure [
            { code: 401, message: 'Unauthorized' }
          ]
        end
        params do
          requires :text, type: String, desc: 'Text of the slack command'
        end
        post 'slack/trigger' do
          if result = SlashCommands::GlobalSlackHandler.new(params).trigger
            status result[:status] || 200
            present result
          else
            not_found!
          end
        end
      end
    end
  end
end
