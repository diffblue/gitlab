# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::Package, type: :model, feature_category: :software_composition_analysis do
  using RSpec::Parameterized::TableSyntax

  let(:purl_types) do
    {
      composer: 1,
      conan: 2,
      gem: 3,
      golang: 4,
      maven: 5,
      npm: 6,
      nuget: 7,
      pypi: 8,
      apk: 9,
      rpm: 10,
      deb: 11,
      cbl_mariner: 12
    }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:purl_type).with_values(purl_types) }
  end

  describe '#license_ids_for' do
    context 'when licenses are present' do
      let(:default) { [5, 7] }
      let(:highest) { '0.0.2' }
      let(:lowest) { '0.0.1' }
      let(:other) { [[[2, 4], ['v0.0.3', 'v0.0.4']], [[3], ['v0.0.5']]] }

      subject(:package) do
        build_stubbed(:pm_package, name: "cliui", purl_type: "npm", licenses: [default, lowest, highest, other])
      end

      context 'and the given version exactly matches one of the versions in other licenses' do
        it 'returns the other licenses' do
          expect(package.license_ids_for(version: "v0.0.4")).to eq([2, 4])
        end
      end

      context 'and the given version does not match any of the versions in other licenses' do
        it 'returns the default licenses' do
          expect(package.license_ids_for(version: "9.9.9")).to eq(default)
        end
      end
    end

    context 'when licenses are not present' do
      where(:test_case_name, :licenses) do
        'licenses are nil'   | nil
        'licenses are empty' | []
      end

      with_them do
        subject(:package) { build_stubbed(:pm_package, name: "cliui", purl_type: "npm", licenses: licenses) }

        it 'returns an empty array' do
          expect(package.license_ids_for(version: "1.0.0")).to eq([])
        end
      end
    end
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:purl_type) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_presence_of(:name) }

    describe 'for licenses' do
      subject(:package) { build_stubbed(:pm_package, licenses: licenses) }

      let(:default) { [1] }
      let(:highest) { '0.0.2' }
      let(:lowest) { '0.0.1' }
      let(:other) { [[[1, 2], ['v0.0.3', 'v0.0.4']], [[3], ['v0.0.5']]] }

      context 'when field is an empty array' do
        let(:licenses) { [] }

        it { is_expected.to be_valid }
      end

      context 'with different field value permutations' do
        where(:test_case_name, :valid, :default_licenses, :lowest_version, :highest_version, :other_licenses) do
          'all valid'           | true  | default    | lowest      | highest     | other
          'nil'                 | false | nil        | lowest      | highest     | other
          'string'              | false | 's'        | lowest      | highest     | other
          'array with string'   | false | ['s']      | lowest      | highest     | other
          'empty array'         | false | []         | lowest      | highest     | other
          'more than max items' | false | ([1] * 11) | lowest      | highest     | other
          'nil'                 | true  | default    | nil         | highest     | other
          'int value'           | false | default    | 1           | highest     | other
          'empty string'        | false | default    | ''          | highest     | other
          'exceeds max chars'   | false | default    | ('v' * 256) | highest     | other
          'nil'                 | true  | default    | lowest      | nil         | other
          'int value'           | false | default    | lowest      | 1           | other
          'empty string'        | false | default    | lowest      | ''          | other
          'exceeds max chars'   | false | default    | lowest      | ('v' * 256) | other
          'empty array'         | true  | default    | lowest      | highest     | []
          'nil'                 | false | default    | lowest      | highest     | nil
          'elts not arrays'     | false | default    | lowest      | highest     | [[1, 'v1.0']]
          '1st elt not array'   | false | default    | lowest      | highest     | [[1, ['v1.0']]]
          '2nd elt not array'   | false | default    | lowest      | highest     | [[[1], 'v1.0']]
          'too many tuples'     | false | default    | lowest      | highest     | [[[1], ['v1.0']] * 11]
          'too many licenses'   | false | default    | lowest      | highest     | [[[1] * 11, ['v1.0']]]
          'too many versions'   | false | default    | lowest      | highest     | [[[1], ['v1.0'] * 51]]
          'invalid license'     | false | default    | lowest      | highest     | [[[1, 2], ['v1']], [[nil], ['v2']]]
          'invalid version'     | false | default    | lowest      | highest     | [[[1, 2], %w[v1 v2]], [[3], [nil]]]
        end

        with_them do
          let(:licenses) { [default_licenses, lowest_version, highest_version, other_licenses] }

          specify { expect(package.valid?).to eq(valid) }
        end
      end
    end
  end
end
