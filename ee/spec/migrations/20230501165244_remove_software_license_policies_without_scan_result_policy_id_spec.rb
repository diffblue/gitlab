# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveSoftwareLicensePoliciesWithoutScanResultPolicyId, feature_category: :security_policy_management do
  let(:migration) { described_class.new }

  let(:software_license_policies) { table(:software_license_policies) }
  let(:projects) { table(:projects) }
  let(:namespace) { table(:namespaces).create!(name: 'name', path: 'path') }
  let(:project) { projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id) }
  let(:scan_result_policies) { table(:scan_result_policies) }
  let(:security_orchestration_policy_configurations) { table(:security_orchestration_policy_configurations) }
  let(:software_licenses) { table(:software_licenses) }

  let!(:security_orchestration_policy_configuration) do
    security_orchestration_policy_configurations.create!(namespace_id: namespace.id,
      security_policy_management_project_id: project.id)
  end

  let!(:scan_result_policy) do
    scan_result_policies.create!(
      security_orchestration_policy_configuration_id: security_orchestration_policy_configuration.id,
      orchestration_policy_idx: 1)
  end

  let!(:spdx_identifier_license) { software_licenses.create!(name: 'spdx license') }

  let!(:license_policy_with_scan_result_policy_id) do
    software_license_policies.create!(project_id: project.id, software_license_id: spdx_identifier_license.id,
      scan_result_policy_id: scan_result_policy.id)
  end

  describe '#up' do
    context 'with orphan software licenses' do
      let!(:license_policy_without_scan_result_policy_id) do
        software_license_policies.create!(project_id: project.id, software_license_id: spdx_identifier_license.id)
      end

      it 'deletes only orphan software licenses' do
        expect { migrate! }.to change { SoftwareLicensePolicy.count }.from(2).to(1)
      end
    end

    context 'without orphan licenses' do
      it 'does not delete any software license' do
        expect { migrate! }.not_to change { SoftwareLicensePolicy.count }
      end
    end
  end
end
