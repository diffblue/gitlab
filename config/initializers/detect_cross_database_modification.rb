# frozen_string_literal: true

# Do not use middleware in tests since we already wrap all tests with
# `PreventCrossDatabaseModification` logic . Also the environment variable
# offers a quick way to disable this check if it is causing problems
unless Rails.env.test? || ENV['DISABLE_CROSS_DATABASE_MODIFICATION_DETECTION']
  require_dependency 'gitlab/middleware/detect_cross_database_modification'

  Gitlab::Application.configure do |config|
    config.middleware.use(Gitlab::Middleware::DetectCrossDatabaseModification)
  end
end
