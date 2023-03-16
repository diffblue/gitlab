# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupOrphanSoftwareLicenses, feature_category: :security_policy_management do
  let(:migration) { described_class.new }

  let(:software_licenses) { table(:software_licenses) }
  let(:software_license_policies) { table(:software_license_policies) }
  let(:projects) { table(:projects) }
  let(:namespace) { table(:namespaces).create!(name: 'name', path: 'path') }
  let(:project) { projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id) }

  let!(:mit_license) { software_licenses.create!(name: 'mit', spdx_identifier: 'MIT') }

  describe '#up' do
    context 'with orphan software licenses' do
      let!(:orphan_license) { software_licenses.create!(name: 'orphan license', spdx_identifier: nil) }

      it 'deletes only orphan software licenses' do
        expect { migrate! }.to change { SoftwareLicense.count }.from(2).to(1)
      end
    end

    context 'without orphan licenses' do
      it 'does not delete any software license' do
        expect { migrate! }.not_to change { SoftwareLicense.count }
      end
    end

    context 'with licenses without spdx_identifier that belong to a project' do
      let!(:nil_spdx_identifier_license) { software_licenses.create!(name: 'nil spdx license', spdx_identifier: nil) }
      let!(:license_policy) do
        software_license_policies.create!(project_id: project.id, software_license_id: nil_spdx_identifier_license.id)
      end

      it 'deletes only software_licenses without spdx_identifier: nil that does not belong to any projects.' do
        expect { migrate! }.not_to change { SoftwareLicense.count }
      end
    end
  end
end
