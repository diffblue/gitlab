# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SoftwareLicensePolicies::DeleteService, feature_category: :security_policy_management do
  subject(:service) { described_class.new(project, user) }

  let_it_be(:project) { create(:project) }

  let(:user) do
    create(:user).tap do |u|
      project.add_maintainer(u)
    end
  end

  let(:software_license) { create(:software_license) }
  let(:software_license_policy) { create(:software_license_policy, :denied, software_license: software_license) }

  describe '#execute' do
    context 'when software_license has one software_license_policy' do
      it 'deletes software_license_policy and software_license' do
        service.execute(software_license_policy)

        expect { software_license_policy.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { software_license.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when software_license has spdx_identifier' do
      let(:software_license) { create(:software_license, :mit) }

      it 'deletes software_license_policy only' do
        service.execute(software_license_policy)

        expect { software_license_policy.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { software_license.reload }.not_to raise_error
      end
    end

    context 'when software_license has multiple software_license_policies' do
      before do
        create(:software_license_policy, software_license: software_license)
      end

      it 'deletes software_license_policy only' do
        service.execute(software_license_policy)

        expect { software_license_policy.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { software_license.reload }.not_to raise_error
      end
    end
  end
end
