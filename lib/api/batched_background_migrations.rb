# frozen_string_literal: true

module API
  class BatchedBackgroundMigrations < ::API::Base
    include PaginationParams

    feature_category :database
    urgency :low

    before do
      authenticated_as_admin!
    end

    namespace 'databases/:database' do
      resources 'batched_background_migrations' do
        desc 'Get the list of the batched background migrations'
        params do
          optional :database, type: String, desc: 'The name of the database, the default `main`'
        end
        get do
          selected_database = params[:database] || Gitlab::Database::MAIN_DATABASE_NAME
          background_migrations = ::BackgroundMigrationsFinder.new(database: selected_database).execute

          present_entity(paginate(background_migrations))
        end

        desc 'Get the status about one background migration'
        params do
          optional :database, type: String, desc: 'The name of the database, the default `main`'
        end
        get do
          selected_database = params[:database] || Gitlab::Database::MAIN_DATABASE_NAME
          background_migrations = Gitlab::Database::BackgroundMigration.f

          present_entity(paginate(background_migrations))
        end
      end
    end

    helpers do
      def present_entity(result)
        present result,
          with: ::API::Entities::BatchedBackgroundMigration
      end
    end
  end
end
