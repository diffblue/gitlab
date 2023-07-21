# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::CompressedPackageDataObject, feature_category: :software_composition_analysis do
  describe '.create' do
    let(:purl_type) { 'npm' }

    subject(:create) { described_class.create(hash, purl_type) }

    context 'when hash is well-formed' do
      let(:hash) do
        { "name" => "xpp3/xpp3", "lowest_version" => "1.1.4c",
          "other_licenses" => [{ "licenses" => ["unknown"], "versions" => ["1.1.2a", "1.1.2a_min", "1.1.3.3",
            "1.1.3.3_min", "1.1.3.4.O", "1.1.3.4-RC3", "1.1.3.4-RC8"] }],
          "highest_version" => "2.3.5d", "default_licenses" => ["unknown", "Apache-1.1", "CC-PDDC"] }
      end

      it {
        is_expected.to eq(described_class.new(purl_type: purl_type, name: 'xpp3/xpp3',
          default_licenses: ['unknown', 'Apache-1.1', 'CC-PDDC'], lowest_version: '1.1.4c', highest_version: '2.3.5d',
          other_licenses: [{ 'licenses' => ['unknown'],
                             'versions' => ['1.1.2a', '1.1.2a_min', '1.1.3.3', '1.1.3.3_min', '1.1.3.4.O',
                               '1.1.3.4-RC3', '1.1.3.4-RC8'] }]))
      }
    end

    context 'when hash is missing attribute' do
      subject(:create!) { described_class.create(hash, purl_type) }

      context 'and it is name' do
        let(:hash) {  { "default_licenses" => ["unknown", "Apache-1.1", "CC-PDDC"] } }

        specify { expect { create! }.to raise_error(ArgumentError) }
      end

      context 'and it is default_licenses' do
        let(:hash) { { "name" => "xpp3/xpp3" } }

        specify { expect { create! }.to raise_error(ArgumentError) }
      end

      context 'and it is not madantory' do
        let(:hash) { { "name" => "xpp3/xpp3", "default_licenses" => ["unknown", "Apache-1.1", "CC-PDDC"] } }

        specify { expect { create! }.not_to raise_error }
      end
    end
  end

  describe '==' do
    let(:purl_type) { 'npm' }
    let(:name) { 'xpp3/xpp3' }
    let(:default_licenses) { ['unknown', 'Apache-1.1', 'CC-PDDC'] }
    let(:lowest_version) { '1.1.4c' }
    let(:highest_version) { '2.3.5d' }
    let(:other_licenses) do
      [{ 'licenses' => ['unknown'],
         'versions' => ['1.1.2a', '1.1.2a_min', '1.1.3.3', '1.1.3.3_min', '1.1.3.4.O', '1.1.3.4-RC3', '1.1.3.4-RC8'] }]
    end

    let(:obj) do
      described_class.new(purl_type: purl_type, name: name, default_licenses: default_licenses,
        lowest_version: lowest_version, highest_version: highest_version, other_licenses: other_licenses)
    end

    subject(:equality) { obj == other }

    context 'when all attributes are equal' do
      let(:other) { obj }

      it { is_expected.to eq(true) }
    end

    context 'when names do not match' do
      let(:other) { obj.dup.tap { |o| o.instance_variable_set(:@name, other_name) } }

      context 'and they are different' do
        let(:other_name) { "#{obj.name}foo" }

        it { is_expected.to eq(false) }
      end

      context 'and their case is different' do
        let(:other_name) { obj.name.upcase }

        context 'and not pypi' do
          let(:purl_type) { 'rubygem' }

          it { is_expected.to eq(false) }
        end

        context 'and pypi' do
          let(:purl_type) { 'pypi' }

          it { is_expected.to eq(true) }
        end
      end
    end

    context 'when default_licenses does not match' do
      let(:other) { obj.dup.tap { |o| o.default_licenses = ['foo'] } }

      it { is_expected.to eq(false) }
    end

    context 'when lowest_version does not match' do
      let(:other) { obj.dup.tap { |o| o.lowest_version = 'baz' } }

      it { is_expected.to eq(false) }
    end

    context 'when highest_version does not match' do
      let(:other) { obj.dup.tap { |o| o.highest_version = 'baz' } }

      it { is_expected.to eq(false) }
    end

    context 'when other_licenses does not match' do
      let(:other) { obj.dup.tap { |o| o.other_licenses = [{ 'licenses' => ['buz'], 'versions' => ['boz'] }] } }

      it { is_expected.to eq(false) }
    end
  end

  describe '.spdx_identifiers' do
    let(:purl_type) { 'npm' }
    let(:name) { 'xpp3/xpp3' }
    let(:default_licenses) { ['unknown', 'Apache-1.1', 'CC-PDDC'] }
    let(:lowest_version) { '1.1.4c' }
    let(:highest_version) { '2.3.5d' }
    let(:other_licenses) do
      [{ 'licenses' => %w[unknown CC-PDDC],
         'versions' => ['1.1.2a', '1.1.2a_min', '1.1.3.3', '1.1.3.3_min', '1.1.3.4.O', '1.1.3.4-RC3', '1.1.3.4-RC8'] }]
    end

    let(:obj) do
      described_class.new(purl_type: purl_type, name: name, default_licenses: default_licenses,
        lowest_version: lowest_version, highest_version: highest_version, other_licenses: other_licenses)
    end

    subject(:spdx_identifiers) { obj.spdx_identifiers }

    it 'sorts licenses and removes duplicates' do
      expect(spdx_identifiers).to eq(%w[Apache-1.1 CC-PDDC unknown])
    end

    # See https://gitlab.com/gitlab-org/gitlab/-/issues/418114
    it 'does not mutate default_licenses' do
      expect { spdx_identifiers }.not_to change { obj.default_licenses }
    end
  end
end
