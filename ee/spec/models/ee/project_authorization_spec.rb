# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectAuthorization do
  describe 'scopes' do
    describe '.eligible_approvers_by_project_id_and_access_levels' do
      let_it_be(:project) { create(:project) }
      let(:guest) { create(:user) }
      let(:developer) { create(:user) }
      let(:maintainer) { create(:user) }
      let(:access_levels) { [::Gitlab::Access::DEVELOPER, ::Gitlab::Access::MAINTAINER] }

      before do
        project.add_guest(guest)
        project.add_developer(developer)
        project.add_maintainer(maintainer)
      end

      subject(:approver_ids) do
        described_class
          .eligible_approvers_by_project_id_and_access_levels([project], access_levels)
          .pluck_user_ids
      end

      it 'returns users with sufficient project access level' do
        expect(approver_ids).to contain_exactly(developer.id, maintainer.id)
      end
    end
  end

  describe '.visible_to_user_and_access_level' do
    let(:user) { create(:user) }
    let(:project1) { create(:project) }
    let(:project2) { create(:project) }

    it 'returns the records for given user that have at least the given access' do
      described_class.create!(user: user, project: project2, access_level: Gitlab::Access::DEVELOPER)
      maintainer_access = described_class.create!(user: user, project: project1, access_level: Gitlab::Access::MAINTAINER)

      authorizations = described_class.visible_to_user_and_access_level(user, Gitlab::Access::MAINTAINER)

      expect(authorizations.count).to eq(1)
      expect(authorizations[0].user_id).to eq(maintainer_access.user_id)
      expect(authorizations[0].project_id).to eq(maintainer_access.project_id)
      expect(authorizations[0].access_level).to eq(maintainer_access.access_level)
    end
  end
end
