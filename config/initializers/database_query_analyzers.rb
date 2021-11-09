# frozen_string_literal: true

# Currently we register validator only for `dev` or `test` environment
if Gitlab.dev_or_test_env? || Gitlab::Utils.to_boolean('GITLAB_ENABLE_QUERY_ANALYZERS', default: false)
  Gitlab::Database::QueryAnalyzer.instance.hook!

  Gitlab::Application.configure do |config|
    # ApolloUploadServer::Middleware expects to find uploaded files ready to use
    config.middleware.use(Gitlab::Middleware::QueryAnalyzer)
  end
end
