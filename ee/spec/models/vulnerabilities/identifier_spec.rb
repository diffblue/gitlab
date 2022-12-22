# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Identifier, feature_category: :vulnerability_management do
  using RSpec::Parameterized::TableSyntax

  describe 'associations' do
    it { is_expected.to have_many(:finding_identifiers).class_name('Vulnerabilities::FindingIdentifier') }
    it { is_expected.to have_many(:findings).class_name('Vulnerabilities::Finding') }
    it { is_expected.to have_many(:primary_findings).class_name('Vulnerabilities::Finding') }
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    let!(:identifier) { create(:vulnerabilities_identifier) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:external_type) }
    it { is_expected.to validate_presence_of(:external_id) }
    it { is_expected.to validate_presence_of(:fingerprint) }
    # Uniqueness validation doesn't work with binary columns. See TODO in class file
    # it { is_expected.to validate_uniqueness_of(:fingerprint).scoped_to(:project_id) }
  end

  describe '.with_fingerprint' do
    let(:fingerprint) { 'f5724386167705667ae25a1390c0a516020690ba' }

    subject { described_class.with_fingerprint(fingerprint) }

    context 'when identifier has the corresponding fingerprint' do
      let!(:identifier) { create(:vulnerabilities_identifier, fingerprint: fingerprint) }

      it 'selects the identifier' do
        is_expected.to match_array([identifier])
      end
    end

    context 'when identifier does not have the corresponding fingerprint' do
      let!(:identifier) { create(:vulnerabilities_identifier) }

      it 'does not select the identifier' do
        is_expected.to be_empty
      end
    end
  end

  describe '.with_external_type' do
    let(:external_type_scope) { 'cwe' }
    let(:external_type_not_in_scope) { 'cve' }

    subject { described_class.with_external_type(external_type_scope) }

    context 'when identifier has the corresponding external_type' do
      let!(:identifier) { create(:vulnerabilities_identifier, external_type: external_type_scope) }

      it 'selects the identifier' do
        is_expected.to match_array([identifier])
      end
    end

    context 'when identifier does not have the corresponding external_type' do
      let!(:identifier) { create(:vulnerabilities_identifier, external_type: external_type_not_in_scope) }

      it 'does not select the identifier' do
        is_expected.to be_empty
      end
    end
  end

  describe 'type check methods' do
    shared_examples_for 'type check method' do |method:|
      with_them do
        let(:identifier) { build_stubbed(:vulnerabilities_identifier, external_type: external_type) }

        subject { identifier.public_send(method) }

        it { is_expected.to be(expected_value) }
      end
    end

    describe '#cve?' do
      it_behaves_like 'type check method', method: :cve? do
        where(:external_type, :expected_value) do
          'CVE' | true
          'cve' | true
          'CWE' | false
          'cwe' | false
          'foo' | false
        end
      end
    end

    describe '#cwe?' do
      it_behaves_like 'type check method', method: :cwe? do
        where(:external_type, :expected_value) do
          'CWE' | true
          'cwe' | true
          'CVE' | false
          'cve' | false
          'foo' | false
        end
      end
    end

    describe '#other?' do
      it_behaves_like 'type check method', method: :other? do
        where(:external_type, :expected_value) do
          'CWE' | false
          'cwe' | false
          'CVE' | false
          'cve' | false
          'foo' | true
        end
      end
    end
  end
end
