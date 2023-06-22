# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Latest::UserInstanceProxy, feature_category: :global_search do
  let_it_be_with_reload(:user) { create(:user, :admin, :public_email) }

  subject { described_class.new(user, use_separate_indices: true) }

  describe '#as_indexed_json' do
    let(:result) { subject.as_indexed_json.with_indifferent_access }

    it 'serializes project as hash' do
      expect(result).to include(
        id: user.id,
        username: user.username,
        email: user.email,
        public_email: user.public_email,
        name: user.name,
        created_at: user.created_at,
        updated_at: user.updated_at,
        admin: true,
        state: 'active',
        external: false,
        organization: user.organization,
        timezone: user.timezone,
        in_forbidden_state: false,
        status: nil,
        status_emoji: nil,
        busy: false,
        namespace_ancestry_ids: [],
        type: 'user'
      )
    end

    context 'with a user status' do
      let_it_be(:user_status) { create(:user_status, :busy) }

      before do
        user.status = user_status
        user.save!
      end

      it 'sets status, status emoji and busy fields' do
        expect(result[:status]).to eq(user_status.message)
        expect(result[:status_emoji]).to eq(user_status.emoji)
        expect(result[:busy]).to eq(true)
      end
    end

    context 'when user is blocked' do
      let_it_be(:user) { create(:user, :blocked) }

      it 'sets in_forbidden_state to true' do
        expect(result[:in_forbidden_state]).to eq(true)
      end
    end

    context 'with a project' do
      let_it_be_with_reload(:project) { create(:project) }

      before do
        project.add_developer(user)
        project.project_feature.update_attribute(:issues_access_level, ProjectFeature::DISABLED)
      end

      it 'sets the correct namespace_ancestry_ids' do
        expect(result[:namespace_ancestry_ids]).to match_array(["#{project.namespace.id}-p#{project.id}-"])
      end

      context 'when project is in a subgroup' do
        let_it_be(:group) { create(:group) }
        let_it_be(:subgroup) { create(:group, parent: group) }
        let(:group_ancestry_id) { "#{group.id}-" }
        let(:subgroup_ancestry_id) { "#{group.id}-#{subgroup.id}-" }
        let(:project_ancestry_id) { "#{group.id}-#{subgroup.id}-p#{project.id}-" }

        before do
          project.group = subgroup
          project.save!
        end

        it 'includes the project ancestry id' do
          expect(result[:namespace_ancestry_ids].count).to eq(1)
          expect(result[:namespace_ancestry_ids]).to include(project_ancestry_id)
        end

        context 'when the user belongs to the group' do
          let_it_be(:group_member) { create(:group_member, group: group, user: user) }

          it 'includes the group ancestry id' do
            expect(result[:namespace_ancestry_ids].count).to eq(2)
            expect(result[:namespace_ancestry_ids]).to include(
              group_ancestry_id, project_ancestry_id)
          end

          context 'when the user belongs to the subgroup' do
            let_it_be(:subgroup_group_member) { create(:group_member, group: subgroup, user: user) }

            it 'includes the subgroup ancestry id' do
              expect(result[:namespace_ancestry_ids].count).to eq(3)
              expect(result[:namespace_ancestry_ids]).to include(
                group_ancestry_id, subgroup_ancestry_id, project_ancestry_id)
            end
          end
        end
      end
    end
  end

  describe '#es_parent' do
    it 'is nil so that elasticsearch routing is disabled' do
      expect(subject.es_parent).to be_nil
    end
  end
end
