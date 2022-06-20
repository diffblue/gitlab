# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::PopulateStatusColumnOfSecurityScans,
               :suppress_gitlab_schemas_validate_connection, schema: 20211007155221 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:builds) { table(:ci_builds) }
  let(:security_scans) { table(:security_scans) }

  let(:namespace) { namespaces.create!(name: 'foo', path: 'bar') }
  let(:project) { projects.create!(namespace_id: namespace.id) }
  let(:pipeline) { pipelines.create!(project_id: project.id, ref: 'master', sha: 'adf43c3a', status: 'success') }
  let(:ci_build_1) { builds.create!(commit_id: pipeline.id, retried: false, type: 'Ci::Build', status: 'success') }
  let(:ci_build_2) { builds.create!(commit_id: pipeline.id, retried: false, type: 'Ci::Build', status: 'failed') }

  let!(:security_scan_1) { security_scans.create!(build_id: ci_build_1.id, scan_type: 1) }
  let!(:security_scan_2) { security_scans.create!(build_id: ci_build_2.id, scan_type: 1) }

  describe '#perform' do
    subject(:migrate) { described_class.new.perform(security_scan_1.id, security_scan_2.id) }

    it 'changes the status of the security_scan records' do
      expect { migrate }.to change { security_scan_1.reload.status }.to(1)
                        .and change { security_scan_2.reload.status }.to(2)
    end
  end
end
