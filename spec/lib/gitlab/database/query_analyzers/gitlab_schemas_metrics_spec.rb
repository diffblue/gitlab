# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::QueryAnalyzers::GitlabSchemasMetrics do
  let(:analyzer) { described_class }

  before do
    stub_const('Gitlab::Database::QueryAnalyzer::ANALYZERS', [analyzer])
  end

  it 'does not increment metrics if feature flag is disabled' do
    stub_feature_flags(query_analyzer_gitlab_schema_metrics: false)

    expect(analyzer).not_to receive(:analyze)

    process_sql(ActiveRecord::Base, "SELECT 1 FROM projects")
  end

  context 'properly observes all queries', :mocked_ci_connection do
    using RSpec::Parameterized::TableSyntax

    where do
      {
        "for simple query observes schema correctly" => {
          model: ApplicationRecord,
          sql: "SELECT 1 FROM projects",
          expectations: {
            gitlab_schemas: "gitlab_main",
            db_config_name: "main"
          }
        },
        "for query accessing gitlab_ci and gitlab_main" => {
          model: ApplicationRecord,
          sql: "SELECT 1 FROM projects LEFT JOIN ci_builds ON ci_builds.project_id=projects.id",
          expectations: {
            gitlab_schemas: "gitlab_ci,gitlab_main",
            db_config_name: "main"
          }
        },
        "for query accessing gitlab_ci and gitlab_main the gitlab_schemas is always ordered" => {
          model: ApplicationRecord,
          sql: "SELECT 1 FROM ci_builds LEFT JOIN projects ON ci_builds.project_id=projects.id",
          expectations: {
            gitlab_schemas: "gitlab_ci,gitlab_main",
            db_config_name: "main"
          }
        },
        "for query accessing CI database" => {
          model: Ci::ApplicationRecord,
          sql: "SELECT 1 FROM ci_builds",
          expectations: {
            gitlab_schemas: "gitlab_ci",
            db_config_name: "ci"
          }
        }
      }
    end

    with_them do
      it do
        expect(described_class.schemas_metrics).to receive(:increment)
          .with(expectations).and_call_original

        process_sql(model, sql)
      end
    end
  end

  def process_sql(model, sql)
    model.connection.load_balancer.read_write do |connection|
      Gitlab::Database::QueryAnalyzer.new.process_sql(sql, connection)
    end
  end
end
