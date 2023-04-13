# frozen_string_literal: true

require "spec_helper"

RSpec.describe SCA::LicensePolicy, feature_category: :software_composition_analysis do
  subject { described_class.new(license, policy, approval_status) }

  let(:license) { build(:license_scanning_license, :mit) }
  let(:policy) { build(:software_license_policy, software_license: software_license) }
  let(:software_license) { build(:software_license, :mit) }
  let(:approval_status) { nil }

  describe "#id" do
    context "when a software_policy is provided" do
      it { expect(subject.id).to eq(policy.id) }
    end

    context "when a software_policy is NOT provided" do
      let(:policy) { nil }

      it { expect(subject.id).to be_nil }
    end
  end

  describe "#name" do
    context "when a software_policy is provided" do
      it { expect(subject.name).to eq(policy.software_license.name) }
    end

    context "when a software_policy is NOT provided" do
      let(:policy) { nil }

      it { expect(subject.name).to eq(license.name) }
    end

    context "when a reported license is NOT provided" do
      let(:license) { nil }

      it { expect(subject.name).to eq(policy.name) }
    end

    context "when a reported license and policy NOT provided" do
      let(:policy) { nil }
      let(:license) { nil }

      it { expect(subject.name).to be_nil }
    end
  end

  describe "#url" do
    context "when a license is provided" do
      it { expect(subject.url).to eq(license.url) }
    end

    context "when a license is NOT provided" do
      let(:license) { nil }

      it { expect(subject.id).to be_nil }
    end
  end

  describe "#dependencies" do
    context "when a license is provided" do
      it { expect(subject.dependencies).to eq(license.dependencies) }
    end

    context "when a license is NOT provided" do
      let(:license) { nil }

      it { expect(subject.dependencies).to be_empty }
    end
  end

  describe "#classification" do
    context "when a allowed software_policy is provided" do
      let(:policy) { build(:software_license_policy, :allowed, software_license: software_license) }

      it { expect(subject.classification).to eq("allowed") }
    end

    context "when a denied software_policy is provided" do
      let(:policy) { build(:software_license_policy, :denied, software_license: software_license) }

      it { expect(subject.classification).to eq("denied") }
    end

    context "when a software_policy is NOT provided" do
      let(:policy) { nil }

      it { expect(subject.classification).to eq("unclassified") }
    end

    context 'when approval_status is not nil' do
      let(:policy) { nil }
      let(:approval_status) { 'denied' }

      it { expect(subject.classification).to eq("denied") }
    end
  end

  describe "#spdx_identifier" do
    context "when a software_policy is provided" do
      it { expect(subject.spdx_identifier).to eq(policy.software_license.spdx_identifier) }
    end

    context "when a software_policy is provided but does not have a SPDX Id" do
      let(:software_license) { build(:software_license, spdx_identifier: nil) }

      it { expect(subject.spdx_identifier).to eq(license.id) }
    end

    context "when a software_policy is NOT provided" do
      let(:policy) { nil }

      it { expect(subject.spdx_identifier).to eq(license.id) }
    end

    context "when a reported license is NOT provided" do
      let(:license) { nil }

      it { expect(subject.spdx_identifier).to eq(policy.software_license.spdx_identifier) }
    end
  end
end
