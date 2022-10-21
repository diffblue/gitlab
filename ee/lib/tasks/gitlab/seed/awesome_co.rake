# frozen_string_literal: true

namespace :ee do
  namespace :gitlab do
    namespace :seed do
      # @example
      #   $ rake ee:gitlab:seed:awesome_co[awesome_co,12345]
      desc 'Seed test data for a given namespace'
      task :awesome_co, [:co, :namespace_id] => :environment do |_, argv|
        require 'factory_bot'

        namespace = Namespace.find(argv[:namespace_id])
        seed_file = Rails.root.join('ee/db/seeds/awesome_co', "#{argv[:co]}.rb")

        raise 'Invalid seed file' unless File.exist?(seed_file)

        puts "Seeding AwesomeCo demo data for #{namespace.name}"

        require seed_file

        AwesomeCo.seed(User.admins.first)
      end
    end
  end
end
