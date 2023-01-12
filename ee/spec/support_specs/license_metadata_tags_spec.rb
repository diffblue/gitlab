# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'license metadata tags', feature_category: :sm_provisioning do
  it 'applies the with_license metadata tag by default' do |example|
    expect(example.metadata[:with_license]).to eq(true)
  end

  it 'does not apply the without_license metadata tag by default' do |example|
    expect(example.metadata[:without_license]).to be_nil
  end

  it 'has a current license' do
    expect(License.current).to be_present
  end

  context 'with with_license tag', :with_license do
    it 'does not apply the without_license metadata tag' do |example|
      expect(example.metadata[:without_license]).to be_nil
    end

    it 'has a current license' do
      expect(License.current).to be_present
    end
  end

  context 'with without_license tag', :without_license do
    it 'does not have a current license' do
      expect(License.current).to be_nil
    end
  end
end
