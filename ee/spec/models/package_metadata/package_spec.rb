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

  describe 'validation' do
    it { is_expected.to validate_presence_of(:purl_type) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_presence_of(:name) }

    describe 'for licenses' do
      subject(:package) { build(:pm_package, licenses: licenses) }

      let(:default) { [1] }
      let(:highest) { '0.0.2' }
      let(:lowest) { '0.0.1' }
      let(:non_default) { [[[1, 2], ['v0.0.3', 'v0.0.4']], [[3], ['v0.0.5']]] }

      context 'when non_default licenses are empty' do
        let(:licenses) { [default, lowest, highest, []] }

        it { is_expected.to be_valid }
      end

      context 'when field is an empty array' do
        let(:licenses) { [] }

        it { is_expected.to be_valid }
      end

      context 'with different field value permutations' do
        using RSpec::Parameterized::TableSyntax

        where(:test_case_name, :valid, :default_licenses, :lowest_version, :highest_version, :non_default_licenses) do
          'all valid'           | true  | default    | lowest      | highest     | non_default
          'nil'                 | false | nil        | lowest      | highest     | non_default
          'string'              | false | 's'        | lowest      | highest     | non_default
          'array with string'   | false | ['s']      | lowest      | highest     | non_default
          'empty array'         | false | []         | lowest      | highest     | non_default
          'more than max items' | false | ([1] * 11) | lowest      | highest     | non_default
          'nil'                 | true  | default    | nil         | highest     | non_default
          'int value'           | false | default    | 1           | highest     | non_default
          'empty string'        | false | default    | ''          | highest     | non_default
          'exceeds max chars'   | false | default    | ('v' * 256) | highest     | non_default
          'nil'                 | true  | default    | lowest      | nil         | non_default
          'int value'           | false | default    | lowest      | 1           | non_default
          'empty string'        | false | default    | lowest      | ''          | non_default
          'exceeds max chars'   | false | default    | lowest      | ('v' * 256) | non_default
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
          let(:licenses) { [default_licenses, lowest_version, highest_version, non_default_licenses] }

          specify { expect(package.valid?).to eq(valid) }
        end
      end
    end
  end
end
