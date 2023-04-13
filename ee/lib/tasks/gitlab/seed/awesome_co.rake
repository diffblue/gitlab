# frozen_string_literal: true

namespace :ee do
  namespace :gitlab do
    namespace :seed do
      # @example
      #   $ rake "ee:gitlab:seed:awesome_co[path/to/seed/file,12345]"
      desc 'Seed test data for a given namespace'
      task :awesome_co, [:co, :namespace_id] => :environment do |_, argv|
        require 'factory_bot'
        require Rails.root.join('ee/db/seeds/awesome_co/awesome_co.rb')

        seed_file = Rails.root.join('ee/db/seeds/awesome_co', argv[:co])

        raise "Seed file `#{seed_file}` does not exist" unless File.exist?(seed_file)

        puts "Seeding AwesomeCo demo data for #{Namespace.find(argv[:namespace_id]).name}"

        AwesomeCo.seed(User.admins.first, seed_file.to_s)
      end
    end
  end
end
