# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CrossDatabaseModification do
  describe '.transaction' do
    it 'adds gitlab_schema to the current transaction', :aggregate_failures do
      recorder = ActiveRecord::QueryRecorder.new do
        ApplicationRecord.transaction do
          Project.first
        end
      end

      expect(recorder.log).to include(
        /SAVEPOINT.*gitlab_schema:gitlab_main/,
        /SELECT.*FROM "projects"/,
        /RELEASE SAVEPOINT.*gitlab_schema:gitlab_main/
      )

      recorder = ActiveRecord::QueryRecorder.new do
        Ci::ApplicationRecord.transaction do
          Project.first
        end
      end

      expect(recorder.log).to include(
        /SAVEPOINT.*gitlab_schema:gitlab_ci/,
        /SELECT.*FROM "projects"/,
        /RELEASE SAVEPOINT.*gitlab_schema:gitlab_ci/
      )

      recorder = ActiveRecord::QueryRecorder.new do
        Project.transaction do
          Project.first
        end
      end

      expect(recorder.log).to include(
        /SAVEPOINT.*gitlab_schema:gitlab_main/,
        /SELECT.*FROM "projects"/,
        /RELEASE SAVEPOINT.*gitlab_schema:gitlab_main/
      )

      recorder = ActiveRecord::QueryRecorder.new do
        Ci::Pipeline.transaction do
          Project.first
        end
      end

      expect(recorder.log).to include(
        /SAVEPOINT.*gitlab_schema:gitlab_ci/,
        /SELECT.*FROM "projects"/,
        /RELEASE SAVEPOINT.*gitlab_schema:gitlab_ci/
      )
    end

    it 'yields' do
      expect { |block| ApplicationRecord.transaction(&block) }.to yield_control
    end
  end
end
