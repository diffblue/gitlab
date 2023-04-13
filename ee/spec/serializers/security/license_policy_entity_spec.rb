# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::LicensePolicyEntity, feature_category: :software_composition_analysis do
  let(:license) { build(:license_scanning_license, :mit).tap { |x| x.add_dependency(name: 'rails', package_manager: 'bundler', path: './Gemfile.lock', version: '6.0.3.4') } }
  let(:policy) { build(:software_license_policy, :allowed) }
  let(:entity) { described_class.new(SCA::LicensePolicy.new(license, policy)) }

  describe '#as_json' do
    subject { entity.as_json }

    specify { expect(subject[:name]).to eql(policy.name) }
    specify { expect(subject[:classification]).to eql({ id: policy.id, name: policy.name, approval_status: policy.approval_status }) }
    specify { expect(subject[:dependencies]).to match_array([{ name: 'rails', package_manager: 'bundler', version: '6.0.3.4', blob_path: './Gemfile.lock' }]) }
    specify { expect(subject[:count]).to be(1) }
    specify { expect(subject[:url]).to eql(license.url) }
  end
end
