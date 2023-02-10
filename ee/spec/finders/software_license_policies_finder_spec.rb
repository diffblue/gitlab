# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SoftwareLicensePoliciesFinder, feature_category: :security_policy_management do
  let(:project) { create(:project) }
  let(:software_license_policy) { create(:software_license_policy, project: project) }

  let(:user) do
    create(:user).tap do |u|
      project.add_maintainer(u)
    end
  end

  let(:finder) { described_class.new(user, project, params) }

  before do
    stub_licensed_features(license_scanning: true)
  end

  context 'searched by name' do
    let(:params) { { name: software_license_policy.name } }

    it 'by name finds the software license policy by name' do
      expect(finder.execute.take).to eq(software_license_policy)
    end
  end

  context 'with policies from license_finding' do
    let(:params) { { ignore_license_finding: false, name: software_license_policy.name } }
    let!(:software_license_policy) do
      create(:software_license_policy,
        project: project,
        scan_result_policy_read: create(:scan_result_policy_read)
      )
    end

    it 'returns policy from license_finding rules' do
      expect(finder.execute.take).to eq(software_license_policy)
    end
  end

  context 'searched by name_or_id' do
    context 'with a name' do
      let(:params) { { name_or_id: software_license_policy.name } }

      it 'by name_or_id finds the software license policy by name' do
        expect(finder.execute.take).to eq(software_license_policy)
      end
    end

    context 'with an id' do
      let(:params) { { name_or_id: software_license_policy.id.to_s } }

      it 'by name or id finds the software license policy by id' do
        expect(finder.execute.take).to eq(software_license_policy)
      end
    end
  end
end
