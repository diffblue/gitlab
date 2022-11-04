# frozen_string_literal: true

class GitlabShellWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include Gitlab::ShellAdapter

  feature_category :source_code_management
  urgency :high
  weight 2
  loggable_arguments 0

  def perform(action, *arg)
    Gitlab::GitalyClient::NamespaceService.allow do
      gitlab_shell.__send__(action, *arg) # rubocop:disable GitlabSecurity/PublicSend
    end
  end
end
