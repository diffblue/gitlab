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

      let(:valid_default) { [1] }
      let(:valid_highest) { '0.0.1' }
      let(:valid_non_default) { [[[1, 2], ['v0.0.1', 'v0.0.2']], [[3], ['v0.0.3']]] }

      context 'when all 3 fields are valid' do
        let(:licenses) { [valid_default, valid_highest, valid_non_default] }

        it { is_expected.to be_valid }
      end

      context 'when non_default licenses are empty' do
        let(:licenses) { [valid_default, valid_highest, []] }

        it { is_expected.to be_valid }
      end

      context 'when invalid fields exist' do
        using RSpec::Parameterized::TableSyntax

        where(:test_case_name, :valid, :default_licenses, :highest_version, :non_default_licenses) do
          'all valid'           | true  | valid_default | valid_highest | valid_non_default
          'all nil'             | true  | nil           | nil           | nil
          '2 nil'               | false | valid_default | nil           | nil
          'nil'                 | false | nil           | valid_highest | valid_non_default
          'string'              | false | 's'           | valid_highest | valid_non_default
          'array with string'   | false | ['s']         | valid_highest | valid_non_default
          'empty array'         | false | []            | valid_highest | valid_non_default
          'more than max items' | false | ([1] * 11)    | valid_highest | valid_non_default
          'nil'                 | false | valid_default | nil           | valid_non_default
          'int value'           | false | valid_default | 1             | valid_non_default
          'empty string'        | false | valid_default | ''            | valid_non_default
          'exceeds max chars'   | false | valid_default | ('v' * 256)   | valid_non_default
          'empty array'         | true  | valid_default | valid_highest | []
          'nil'                 | false | valid_default | valid_highest | nil
          'elts not arrays'     | false | valid_default | valid_highest | [[[1, 'v1.0']]]
          '1st elt not array'   | false | valid_default | valid_highest | [[[1, ['v1.0']]]]
          '2nd elt not array'   | false | valid_default | valid_highest | [[[[1], 'v1.0']]]
          'too many tuples'     | false | valid_default | valid_highest | [[[[1], ['v1.0']] * 11]]
          'too many licenses'   | false | valid_default | valid_highest | [[[1] * 11, ['v1.0']]]
          'too many versions'   | false | valid_default | valid_highest | [[[1], ['v1.0'] * 51]]
          'any license invalid' | false | valid_default | valid_highest | [[[[1, 2], ['v1']], [[nil], ['v2']]]]
          'any version invalid' | false | valid_default | valid_highest | [[[[1, 2], %w[v1 v2]], [[3], [nil]]]]
        end

        with_them do
          let(:licenses) { [default_licenses, highest_version, non_default_licenses].compact }

          specify { expect(package.valid?).to eq(valid) }
        end
      end
    end
  end
end
