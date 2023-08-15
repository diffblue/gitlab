# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::AffectedPackageDataObject, feature_category: :software_composition_analysis do
  describe '.create' do
    let(:purl_type) { 'npm' }
    let(:hash) do
      {
        "name" => "org.jenkins-ci.plugins/google-kubernetes-engine",
        "affected_range" => "(,0.7.0]",
        "solution" => "Upgrade to version 0.8 or above.",
        "fixed_versions" => ["0.8"],
        "versions" => [{ 'number' => '1.2.3',
                         'commit' => { 'tags' => ['v1.2.3-tag'], 'sha' => '295cf0778821bf08681e2bd0ef0e6cad04fc3001',
                                       'timestamp' => '20190626162700' } }]
      }
    end

    subject(:create) { described_class.create(hash, purl_type) }

    it { is_expected.to be_kind_of(described_class) }

    it do
      is_expected.to match(have_attributes(purl_type: 'npm',
        package_name: 'org.jenkins-ci.plugins/google-kubernetes-engine', affected_range: '(,0.7.0]',
        solution: 'Upgrade to version 0.8 or above.', fixed_versions: ["0.8"],
        "versions" => [{ 'number' => '1.2.3',
                         'commit' => { 'tags' => ['v1.2.3-tag'], 'sha' => '295cf0778821bf08681e2bd0ef0e6cad04fc3001',
                                       'timestamp' => '20190626162700' } }]))
    end

    context 'when an attribute is missing' do
      using RSpec::Parameterized::TableSyntax

      subject(:create!) { described_class.create(hash.except(attribute.to_s), purl_type) }

      where(:attribute, :required) do
        :distro_version | false
        :solution       | false
        :fixed_versions | false
        :versions       | false
        :name           | true
        :affected_range | true
      end

      with_them do
        specify do
          required ? expect { create! }.to(raise_error(ArgumentError)) : expect { create! }.not_to(raise_error)
        end
      end
    end
  end
end
