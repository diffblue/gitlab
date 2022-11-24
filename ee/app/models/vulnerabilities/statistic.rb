# frozen_string_literal: true

module Vulnerabilities
  class Statistic < ApplicationRecord
    self.table_name = 'vulnerability_statistics'

    belongs_to :project, optional: false
    belongs_to :pipeline, class_name: 'Ci::Pipeline', foreign_key: :latest_pipeline_id

    enum letter_grade: { a: 0, b: 1, c: 2, d: 3, f: 4 }

    validates :total, numericality: { greater_than_or_equal_to: 0 }
    validates :critical, numericality: { greater_than_or_equal_to: 0 }
    validates :high, numericality: { greater_than_or_equal_to: 0 }
    validates :medium, numericality: { greater_than_or_equal_to: 0 }
    validates :low, numericality: { greater_than_or_equal_to: 0 }
    validates :unknown, numericality: { greater_than_or_equal_to: 0 }
    validates :info, numericality: { greater_than_or_equal_to: 0 }

    before_save :assign_letter_grade

    scope :for_project, ->(project) { where(project_id: project) }
    scope :by_grade, -> (grade) { where(letter_grade: grade) }

    class << self
      # Takes an object which responds to `#[]` method call
      # like an instance of ActiveRecord::Base or a Hash and
      # returns the letter grade value for given object.
      def letter_grade_for(object)
        if object['critical'].to_i > 0
          letter_grades[:f]
        elsif object['high'].to_i > 0 || object['unknown'].to_i > 0
          letter_grades[:d]
        elsif object['medium'].to_i > 0
          letter_grades[:c]
        elsif object['low'].to_i > 0
          letter_grades[:b]
        else
          letter_grades[:a]
        end
      end

      def letter_grade_sql_for(target_values, excluded_values)
        <<~SQL
          SELECT (
            CASE
            WHEN TARGET.critical + EXCLUDED.critical > 0 THEN
              #{Vulnerabilities::Statistic.letter_grades[:f]}
            WHEN TARGET.high + TARGET.unknown + EXCLUDED.high + EXCLUDED.unknown > 0 THEN
              #{Vulnerabilities::Statistic.letter_grades[:d]}
            WHEN TARGET.medium + EXCLUDED.medium > 0 THEN
              #{Vulnerabilities::Statistic.letter_grades[:c]}
            WHEN TARGET.low + EXCLUDED.low > 0 THEN
              #{Vulnerabilities::Statistic.letter_grades[:b]}
            ELSE
              #{Vulnerabilities::Statistic.letter_grades[:a]}
            END
          ) as letter_grade
          FROM
            (values #{target_values}) as TARGET (critical, unknown, high, medium, low),
            (values #{excluded_values}) as EXCLUDED (critical, unknown, high, medium, low)
        SQL
      end

      def set_latest_pipeline_with(pipeline)
        upsert_sql = upsert_latest_pipeline_id_sql(pipeline)

        connection.execute(upsert_sql)
      end

      private

      UPSERT_LATEST_PIPELINE_ID_SQL_TEMPLATE = <<~SQL
        INSERT INTO %<table_name>s AS target (project_id, latest_pipeline_id, letter_grade, created_at, updated_at)
          VALUES (%{project_id}, %<latest_pipeline_id>d, %<letter_grade>d, now(), now())
        ON CONFLICT (project_id)
          DO UPDATE SET
            latest_pipeline_id = %<latest_pipeline_id>d, updated_at = now()
      SQL

      private_constant :UPSERT_LATEST_PIPELINE_ID_SQL_TEMPLATE

      def upsert_latest_pipeline_id_sql(pipeline)
        format(UPSERT_LATEST_PIPELINE_ID_SQL_TEMPLATE,
               table_name: table_name,
               project_id: pipeline.project.id,
               latest_pipeline_id: pipeline.id,
               letter_grade: letter_grades[:a])
      end
    end

    private

    def assign_letter_grade
      self.letter_grade = self.class.letter_grade_for(self)
    end
  end
end
