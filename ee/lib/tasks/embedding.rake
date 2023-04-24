# frozen_string_literal: true

task spec: ['db:test:prepare:embedding']

db_namespace = namespace :db do
  namespace :seed do
    seed_loader = Class.new do
      def self.load_seed
        load('ee/db/embedding/seeds.rb')
      end
    end

    desc "Loads the seed data from ee/db/embedding/seeds.rb"
    task embedding: :load_config do
      db_namespace["abort_if_pending_migrations:embedding"].invoke
      ActiveRecord::Tasks::DatabaseTasks.seed_loader = seed_loader
      ActiveRecord::Tasks::DatabaseTasks.load_seed
    end
  end
end
