# frozen_string_literal: true

module Iterations
  class Cadence < ApplicationRecord
    include BulkInsertSafe

    self.table_name = 'iterations_cadences'
  end
end

Gitlab::Seeder.quiet do
  Group.not_mass_generated.each do |group|
    cadences = []
    1000.times do
      random_number = rand(5)
      cadence_params = {
        title: FFaker::Lorem.sentence(6),
        start_date: rand(1..14).days.from_now,
        duration_in_weeks: random_number == 5 ? nil : random_number,
        iterations_in_advance: random_number == 5 ? nil : random_number,
        active: rand(2),
        automatic: rand(2),
        group_id: group.id,
        created_at: Time.now,
        updated_at: Time.now
      }

      print '.'
      cadences << Iterations::Cadence.new(cadence_params)
    end

    Iterations::Cadence.bulk_insert!(cadences, validate: false)
  end
end
