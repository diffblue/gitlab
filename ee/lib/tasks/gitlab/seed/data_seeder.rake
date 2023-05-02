# frozen_string_literal: true

namespace :ee do
  namespace :gitlab do
    namespace :seed do
      # @example
      #   $ rake "ee:gitlab:seed:data_seeder[path/to/seed/file,12345]"
      desc 'Seed test data for a given namespace'
      task :data_seeder, [:co, :namespace_id] => :environment do |_, argv|
        require 'factory_bot'
        require Rails.root.join('ee/db/seeds/data_seeder/data_seeder.rb')

        seed_file = Rails.root.join('ee/db/seeds/data_seeder', argv[:co])

        raise "Seed file `#{seed_file}` does not exist" unless File.exist?(seed_file)

        puts "Seeding demo data for #{Namespace.find(argv[:namespace_id]).name}"

        Gitlab::DataSeeder.seed(User.admins.first, seed_file.to_s)
      end
    end
  end
end
