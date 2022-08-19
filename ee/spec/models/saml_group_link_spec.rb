# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SamlGroupLink do
  describe 'associations' do
    it { is_expected.to belong_to(:group) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:access_level) }
    it { is_expected.to validate_presence_of(:saml_group_name) }
    it { is_expected.to validate_length_of(:saml_group_name).is_at_most(255) }

    context 'group name uniqueness' do
      before do
        create(:saml_group_link, group: create(:group))
      end

      it { is_expected.to validate_uniqueness_of(:saml_group_name).scoped_to([:group_id]) }
    end

    context 'saml_group_name with whitespaces' do
      it 'saves group link name without whitespace' do
        saml_group_link = described_class.new(saml_group_name: '   group   ')
        saml_group_link.valid?

        expect(saml_group_link.saml_group_name).to eq('group')
      end
    end

    context 'minimal access role' do
      let_it_be(:top_level_group) { create(:group) }
      let_it_be(:subgroup) { create(:group, parent: top_level_group) }

      def saml_group_link(group:)
        build(:saml_group_link, group: group, access_level: ::Gitlab::Access::MINIMAL_ACCESS)
      end

      before do
        stub_licensed_features(minimal_access_role: true)
      end

      it 'allows the role at the top level group' do
        expect(saml_group_link(group: top_level_group)).to be_valid
      end

      it 'does not allow the role for subgroups' do
        expect(saml_group_link(group: subgroup)).not_to be_valid
      end
    end
  end

  describe '.by_id_and_group_id' do
    let_it_be(:group) { create(:group) }
    let_it_be(:group_link) { create(:saml_group_link, group: group) }

    it 'finds the group link' do
      results = described_class.by_id_and_group_id(group_link.id, group.id)

      expect(results).to match_array([group_link])
    end

    context 'with multiple groups and group links' do
      let_it_be(:group2) { create(:group) }
      let_it_be(:group_link2) { create(:saml_group_link, group: group2) }

      it 'finds group links within the given groups' do
        results = described_class.by_id_and_group_id([group_link, group_link2], [group, group2])

        expect(results).to match_array([group_link, group_link2])
      end

      it 'does not find group links outside the given groups' do
        results = described_class.by_id_and_group_id([group_link, group_link2], [group])

        expect(results).to match_array([group_link])
      end
    end
  end

  describe '.by_saml_group_name' do
    let_it_be(:group) { create(:group) }
    let_it_be(:group_link) { create(:saml_group_link, group: group) }

    it 'finds the group link' do
      results = described_class.by_saml_group_name(group_link.saml_group_name)

      expect(results).to match_array([group_link])
    end

    context 'with multiple groups and group links' do
      let_it_be(:group2) { create(:group) }
      let_it_be(:group_link2) { create(:saml_group_link, group: group2) }

      it 'finds group links within the given groups' do
        results = described_class.by_saml_group_name([group_link.saml_group_name, group_link2.saml_group_name])

        expect(results).to match_array([group_link, group_link2])
      end
    end
  end
end
