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
        using RSpec::Parameterized::TableSyntax

        # rubocop:disable Layout/LineLength
        where(:test_case_name, :valid, :default_licenses, :lowest_version, :highest_version, :other_licenses) do
          'all attributes valid'            | true  | default     | lowest      | highest     | other
          'default nil'                     | false | nil         | lowest      | highest     | other
          'default not arr'                 | false | 's'         | lowest      | highest     | other
          'default arr elts not ints'       | false | ['s']       | lowest      | highest     | other
          'default empty arr'               | false | []          | lowest      | highest     | other
          'default num elts up to max'      | true  | ([1] * 100) | lowest      | highest     | other
          'default num elts exceed max'     | false | ([1] * 101) | lowest      | highest     | other
          'lowest nil'                      | true  | default     | nil         | highest     | other
          'lowest int'                      | false | default     | 1           | highest     | other
          'lowest empty str'                | false | default     | ''          | highest     | other
          'lowest version len up to max'    | true  | default     | ('v' * 255) | highest     | other
          'lowest version len exceeds max'  | false | default     | ('v' * 256) | highest     | other
          'highest nil'                     | true  | default     | lowest      | nil         | other
          'highest int'                     | false | default     | lowest      | 1           | other
          'highest empty str'               | false | default     | lowest      | ''          | other
          'highest version len up to max'   | true  | default     | lowest      | ('v' * 255) | other
          'highest version len exceeds max' | false | default     | lowest      | ('v' * 256) | other
          'other empty arr'                 | true  | default     | lowest      | highest     | []
          'other nil'                       | false | default     | lowest      | highest     | nil
          '1st elt not arr'                 | false | default     | lowest      | highest     | [[1, ['v1']]]
          '2nd elt not arr'                 | false | default     | lowest      | highest     | [[[1], 'v1']]
          'default num tuples up to max'    | true  | default     | lowest      | highest     | Array.new(20) { [[1], ['v1']] }
          'default num tuples exceed max'   | false | default     | lowest      | highest     | Array.new(21) { [[1], ['v1']] }
          'default num licenses up to max'  | true  | default     | lowest      | highest     | [[Array.new(100) { 1 }, ['v1']]]
          'default num licenses exceed max' | false | default     | lowest      | highest     | [[Array.new(101) { 1 }, ['v1']]]
          'default num versions up to max'  | true  | default     | lowest      | highest     | [[[1], Array.new(500) { 'v1' }]]
          'default num versions exceed max' | false | default     | lowest      | highest     | [[[1], Array.new(501) { 'v1' }]]
        end
        # rubocop:enable Layout/LineLength

        with_them do
          let(:licenses) { [default_licenses, lowest_version, highest_version, other_licenses] }

          specify { expect(package.valid?).to eq(valid) }
        end
      end
    end
  end
end
