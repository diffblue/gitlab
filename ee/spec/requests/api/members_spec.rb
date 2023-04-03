# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Members, feature_category: :subgroups do
  include EE::API::Helpers::MembersHelpers

  context 'group members endpoints for group with minimal access feature' do
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:minimal_access_member) { create(:group_member, :minimal_access, source: group) }
    let_it_be(:owner) { create(:user) }

    before do
      group.add_owner(owner)
      subgroup.add_owner(owner)
    end

    describe "GET /groups/:id/members" do
      subject do
        get api("/groups/#{group.id}/members", owner)
        json_response
      end

      it 'returns user with minimal access when feature is available' do
        stub_licensed_features(minimal_access_role: true)

        expect(subject.map { |u| u['id'] }).to match_array [owner.id, minimal_access_member.user_id]
      end

      it 'does not return user with minimal access when feature is unavailable' do
        stub_licensed_features(minimal_access_role: false)

        expect(subject.map { |u| u['id'] }).not_to include(minimal_access_member.user_id)
      end
    end

    describe 'POST /groups/:id/members' do
      let_it_be(:stranger) { create(:user) }
      let(:access_level) { Gitlab::Access::GUEST }

      subject(:post_members) do
        post api("/groups/#{group.id}/members", owner),
             params: { user_id: stranger.id, access_level: access_level }
      end

      context 'with free user cap considerations', :saas do
        let_it_be(:group) { create(:group_with_plan, :private, plan: :free_plan) }

        before do
          stub_ee_application_setting(dashboard_limit_enabled: true)
        end

        shared_examples 'does not add members' do
          it 'does not add the member' do
            expect do
              post_members
            end.not_to change { group.members.count }

            msg = "cannot be added since you've reached your #{::Namespaces::FreeUserCap.dashboard_limit} " \
                  "member limit for #{group.name}"
            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to eq({ 'base' => [msg] })
          end
        end

        context 'when there are at the size limit' do
          before do
            stub_ee_application_setting(dashboard_enforcement_limit: 1)
          end

          it_behaves_like 'does not add members'
        end

        context 'when there are over the limit' do
          it_behaves_like 'does not add members'
        end

        context 'when there is a seat left' do
          before do
            stub_ee_application_setting(dashboard_enforcement_limit: 3)
          end

          it 'creates a member' do
            expect { post_members }.to change { group.members.count }.by(1)

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['id']).to eq(stranger.id)
          end
        end
      end

      context 'with minimal access concerns' do
        let(:access_level) { Member::MINIMAL_ACCESS }

        context 'when minimal access license is not available' do
          it 'does not create a member' do
            expect do
              post_members
            end.not_to change { group.all_group_members.count }

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to eq({ 'access_level' => ['is not included in the list', 'not supported by license'] })
          end
        end

        context 'when minimal access license is available' do
          before do
            stub_licensed_features(minimal_access_role: true)
          end

          it 'creates a member' do
            expect do
              post_members
            end.to change { group.all_group_members.count }.by(1)

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['id']).to eq(stranger.id)
          end

          it 'cannot be assigned to subgroup' do
            expect do
              post api("/groups/#{subgroup.id}/members", owner),
                   params: { user_id: stranger.id, access_level: access_level }
            end.not_to change { subgroup.all_group_members.count }

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to eq({ 'access_level' => ['is not included in the list', 'supported on top level groups only'] })
          end
        end
      end
    end

    describe 'PUT /groups/:id/members/:user_id' do
      let(:expires_at) { 2.days.from_now.to_date }
      let(:params) { {} }
      let(:current_user) { owner }

      subject(:put_member) do
        put(
          api("/#{member.source.class.name.downcase}s/#{member.source_id}/members/#{user_id}", current_user),
          params: params
        )
      end

      context 'when setting minimal access role' do
        let(:member) { minimal_access_member }
        let(:user_id) { minimal_access_member.user_id }
        let(:params) { { expires_at: expires_at, access_level: Member::MINIMAL_ACCESS } }

        context 'when minimal access role license is available' do
          before do
            stub_licensed_features(minimal_access_role: true)
          end

          it 'updates the member' do
            put_member

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['id']).to eq(minimal_access_member.user_id)
            expect(json_response['expires_at']).to eq(expires_at.to_s)
          end
        end

        context 'when minimal access role license is not available' do
          before do
            stub_licensed_features(minimal_access_role: false)
          end

          it 'does not update the member' do
            put_member

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'when member_role_id param is present' do
        let_it_be(:member_role) { create(:member_role, :guest, namespace: group) }
        let_it_be(:member) { create(:group_member, :guest, source: group) }

        let(:user_id) { member.user_id }
        let(:params) { { member_role_id: member_role.id, access_level: Member::GUEST } }

        shared_examples 'a successful member role update' do
          it 'updates the member_role' do
            put_member

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['id']).to eq(member.user_id)
            expect(json_response['member_role']['id']).to eq(member_role.id)
          end
        end

        context "when custom roles license is enabled" do
          before do
            stub_licensed_features(custom_roles: true)
          end

          context 'when member_role is associated with membership group' do
            it_behaves_like 'a successful member role update'
          end

          context 'when member_role is associated with root group of subgroup membership' do
            let(:subgroup) { create(:group, parent: group) }
            let(:member) { create(:group_member, :guest, source: subgroup) }

            it_behaves_like 'a successful member role update'
          end

          context 'when member_role is associated with root group of project membership' do
            let_it_be(:project) { create(:project, group: subgroup) }

            let(:member) { create(:project_member, :guest, source: project) }

            it_behaves_like 'a successful member role update'
          end

          context "when member_role has base_access_level that does not match user's access_level" do
            let(:member_role) { create(:member_role, :developer, namespace: group) }
            let(:params) { { member_role_id: member_role.id, access_level: Member::GUEST } }

            it 'raises an error' do
              put_member

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(json_response['message']['member_role_id']).to contain_exactly(
                "role's base access level does not match the access level of the membership"
              )
            end
          end

          context 'when member_role is not associated with root group of member source' do
            let_it_be(:member_role) { create(:member_role, :guest, namespace: create(:group)) }

            it 'raises an error' do
              put_member

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(json_response['message']['member_role']).to contain_exactly('not found')
            end
          end

          context "when invalid member_role_id" do
            let(:params) { { member_role_id: non_existing_record_id, access_level: Member::GUEST } }

            it "returns 400" do
              put_member

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(json_response['message']['member_role']).to contain_exactly('not found')
            end
          end

          context 'when member_role_id is nil' do
            let(:params) { { member_role_id: nil, access_level: Member::REPORTER } }

            it 'unsets the member_role_id attribute for the member' do
              member.update!(member_role: member_role)

              put_member

              expect(response).to have_gitlab_http_status(:ok)
              expect(json_response['id']).to eq(member.user_id)
              expect(json_response['member_role']).to eq(nil)
              expect(json_response['access_level']).to eq(Member::REPORTER)
            end
          end
        end

        context "when custom roles license is disabled" do
          before do
            stub_licensed_features(custom_roles: false)
          end

          it "ignores the member_role_id param" do
            put_member

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['id']).to eq(member.user_id)
            expect(json_response['access_level']).to eq(Member::GUEST)
            expect(json_response['member_role']).to eq(nil)
          end
        end
      end

      describe 'DELETE /groups/:id/members/:user_id' do
        context 'when minimal access role is available' do
          it 'deletes the member' do
            stub_licensed_features(minimal_access_role: true)
            expect do
              delete api("/groups/#{group.id}/members/#{minimal_access_member.user_id}", owner)
            end.to change { group.all_group_members.count }.by(-1)

            expect(response).to have_gitlab_http_status(:no_content)
          end
        end

        context 'when minimal access role is not available' do
          it 'does not delete the member' do
            expect do
              delete api("/groups/#{group.id}/members/#{minimal_access_member.id}", owner)

              expect(response).to have_gitlab_http_status(:not_found)
            end.not_to change { group.all_group_members.count }
          end
        end
      end
    end

    describe 'GET /groups/:id/members/:user_id' do
      context 'when minimal access role is available' do
        it 'shows the member' do
          stub_licensed_features(minimal_access_role: true)
          get api("/groups/#{group.id}/members/#{minimal_access_member.user_id}", owner)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['id']).to eq(minimal_access_member.user_id)
        end
      end

      context 'when minimal access role is not available' do
        it 'does not show the member' do
          get api("/groups/#{group.id}/members/#{minimal_access_member.id}", owner)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  context 'group members endpoint for group managed accounts' do
    let(:group) { create(:group) }
    let(:owner) { create(:user) }

    before do
      group.add_owner(owner)
    end

    include_context "group managed account with group members"

    subject do
      get api(url, owner)
      json_response
    end

    describe "GET /groups/:id/members" do
      let(:url) { "/groups/#{group.id}/members" }

      it_behaves_like 'members response with exposed emails' do
        let(:emails) { gma_member.email }
      end

      it_behaves_like 'members response with hidden emails' do
        let(:emails) { member.email }
      end
    end

    describe "GET /groups/:id/members/:user_id" do
      let(:url) { "/groups/#{group.id}/members/#{user_id}" }

      context 'with group managed account member' do
        let(:user_id) { gma_member.id }

        it_behaves_like 'member response with exposed email' do
          let(:email) { gma_member.email }
        end
      end

      context 'with a regular member' do
        let(:user_id) { member.id }

        it_behaves_like 'member response with hidden email'
      end
    end

    describe "GET /groups/:id/members/all" do
      include_context "child group with group managed account members"

      context 'parent group' do
        let(:url) { "/groups/#{group.id}/members/all" }

        it_behaves_like 'members response with exposed emails' do
          let(:emails) { gma_member.email }
        end

        it_behaves_like 'members response with hidden emails' do
          let(:emails) { member.email }
        end
      end

      context 'child group' do
        let(:url) { "/groups/#{child_group.id}/members/all" }

        it_behaves_like 'members response with exposed emails' do
          let(:emails) { [gma_member.email, child_gma_member.email] }
        end

        it_behaves_like 'members response with hidden emails' do
          let(:emails) { [member.email, child_member.email] }
        end
      end
    end

    describe "GET /groups/:id/members/all/:user_id" do
      include_context "child group with group managed account members"

      let(:url) { "/groups/#{child_group.id}/members/all/#{user_id}" }

      context 'with group managed account member' do
        let(:user_id) { gma_member.id }

        it_behaves_like 'member response with exposed email' do
          let(:email) { gma_member.email }
        end
      end

      context 'with regular member' do
        let(:user_id) { member.id }

        it_behaves_like 'member response with hidden email'
      end

      context 'with group managed account child group member' do
        let(:user_id) { child_gma_member.id }

        it_behaves_like 'member response with exposed email' do
          let(:email) { child_gma_member.email }
        end
      end

      context 'with child group regular member' do
        let(:user_id) { child_member.id }

        it_behaves_like 'member response with hidden email'
      end
    end
  end

  context 'project members endpoint for group managed accounts' do
    let(:group) { create(:group) }
    let(:owner) { create(:user) }
    let(:project) { create(:project, group: group) }

    before do
      group.add_owner(owner)
    end

    include_context "group managed account with project members"

    subject do
      get api(url, owner)
      json_response
    end

    describe "GET /projects/:id/members" do
      let(:url) { "/projects/#{project.id}/members" }

      it_behaves_like 'members response with exposed emails' do
        let(:emails) { gma_member.email }
      end

      it_behaves_like 'members response with hidden emails' do
        let(:emails) { member.email }
      end
    end

    describe "GET /projects/:id/members/:user_id" do
      let(:url) { "/projects/#{project.id}/members/#{user_id}" }

      context 'with group managed account member' do
        let(:user_id) { gma_member.id }

        it_behaves_like 'member response with exposed email' do
          let(:email) { gma_member.email }
        end
      end

      context 'with a regular member' do
        let(:user_id) { member.id }

        it_behaves_like 'member response with hidden email'
      end
    end

    describe "GET /project/:id/members/all" do
      include_context "child project with group managed account members"

      context 'parent group project' do
        let(:url) { "/projects/#{project.id}/members/all" }

        it_behaves_like 'members response with exposed emails' do
          let(:emails) { gma_member.email }
        end

        it_behaves_like 'members response with hidden emails' do
          let(:emails) { member.email }
        end
      end

      context 'child group project' do
        let(:url) { "/projects/#{child_project.id}/members/all" }

        it_behaves_like 'members response with exposed emails' do
          let(:emails) { [child_gma_member.email] }
        end

        it_behaves_like 'members response with hidden emails' do
          let(:emails) { [member.email, child_member.email] }
        end
      end
    end

    describe "GET /projects/:id/members/all/:user_id" do
      include_context "child project with group managed account members"

      let(:url) { "/projects/#{child_project.id}/members/all/#{user_id}" }

      context 'with group managed account member' do
        let(:user_id) { gma_member.id }

        it_behaves_like 'member response with hidden email'
      end

      context 'with regular member' do
        let(:user_id) { member.id }

        it_behaves_like 'member response with hidden email'
      end

      context 'with group managed account child group member' do
        let(:user_id) { child_gma_member.id }

        it_behaves_like 'member response with exposed email' do
          let(:email) { child_gma_member.email }
        end
      end

      context 'with child group regular member' do
        let(:user_id) { child_member.id }

        it_behaves_like 'member response with hidden email'
      end
    end
  end

  context 'billable member endpoints' do
    let_it_be(:owner) { create(:user) }
    let_it_be(:maintainer) { create(:user) }
    let_it_be(:group) do
      create(:group) do |group|
        group.add_owner(owner)
        group.add_maintainer(maintainer)
      end
    end

    let_it_be(:nested_user) { create(:user, name: 'Scott Anderson') }
    let_it_be(:nested_group) do
      create(:group, parent: group) do |nested_group|
        nested_group.add_developer(nested_user)
      end
    end

    describe 'GET /groups/:id/billable_members', feature_category: :seat_cost_management do
      let(:url) { "/groups/#{group.id}/billable_members" }
      let(:params) { {} }

      subject(:get_billable_members) do
        get api(url, owner), params: params
        json_response
      end

      context 'with sub group and projects' do
        let_it_be(:project_user) { create(:user) }
        let_it_be(:project) do
          create(:project, :public, group: nested_group) do |project|
            project.add_developer(project_user)
          end
        end

        let_it_be(:linked_group_user) { create(:user, name: 'Scott McNeil') }
        let_it_be(:linked_group) do
          create(:group) do |linked_group|
            linked_group.add_developer(linked_group_user)
          end
        end

        let_it_be(:project_group_link) { create(:project_group_link, project: project, group: linked_group) }

        it 'returns paginated billable users' do
          get_billable_members

          expect_paginated_array_response(*[owner, maintainer, nested_user, project_user, linked_group_user].map(&:id))
        end

        context 'when the current user does not have the :read_billable_member ability' do
          it 'is a bad request' do
            not_an_owner = create(:user)

            get api(url, not_an_owner), params: params

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end

        context 'with search params provided' do
          let(:params) { { search: nested_user.name } }

          it 'returns the relevant billable users' do
            get_billable_members

            expect_paginated_array_response([nested_user.id])
          end
        end

        context 'with search and sort params provided' do
          it 'accepts only sorting options defined in a list' do
            EE::API::Helpers::MembersHelpers.member_sort_options.each do |sorting|
              get api(url, owner), params: { search: 'name', sort: sorting }
              expect(response).to have_gitlab_http_status(:ok)
            end
          end

          it 'does not accept query string not defined in a list' do
            defined_query_strings = EE::API::Helpers::MembersHelpers.member_sort_options
            sorting = 'fake_sorting'

            get api(url, owner), params: { search: 'name', sort: sorting }

            expect(defined_query_strings).not_to include(sorting)
            expect(response).to have_gitlab_http_status(:bad_request)
          end

          context 'when a specific sorting is provided' do
            let(:params) { { search: 'Scott', sort: 'name_desc' } }

            it 'returns the relevant billable users' do
              get_billable_members

              expect_paginated_array_response(*[linked_group_user, nested_user].map(&:id))
            end
          end
        end

        context 'when sorting users' do
          let_it_be(:sort_group) { create :group }
          let_it_be(:last_activity_on_date) { Date.today - 1.day }
          let_it_be(:user1) { create(:user, last_activity_on: Date.today, current_sign_in_at: DateTime.now - 4.days) }
          let_it_be(:user2) { create(:user, last_activity_on: last_activity_on_date, current_sign_in_at: DateTime.now - 3.days) }
          let_it_be(:user3) { create(:user, last_activity_on: last_activity_on_date, current_sign_in_at: DateTime.now - 2.days) }
          let_it_be(:user4) { create(:user, last_activity_on: last_activity_on_date, current_sign_in_at: DateTime.now - 1.day) }

          let_it_be(:url) { "/groups/#{sort_group.id}/billable_members" }
          let_it_be(:owner) { user1 }

          before do
            sort_group.add_owner(user1)
            [user2, user3, user4].each { |user| sort_group.add_developer(user) }
          end

          context 'with sort param last_activity_on_desc' do
            let(:params) { { sort: 'last_activity_on_desc', per_page: 1, page: 2 } }

            it 'returns paginated users in deterministic order to avoid duplicates and flaky behavior' do
              get_billable_members

              expect_paginated_array_response(user2.id)
            end
          end

          context 'with sort param recent_sign_in' do
            let(:params) { { sort: 'recent_sign_in', per_page: 5, page: 1 } }

            it 'returns paginated users sorted by last_login_at in desc order' do
              get_billable_members

              expect(Time.parse(json_response[0]["last_login_at"])).to be_like_time(user4.current_sign_in_at)
              expect_paginated_array_response(user4.id, user3.id, user2.id, user1.id)
            end
          end

          context 'with sort param oldest_sign_in' do
            let(:params) { { sort: 'oldest_sign_in', per_page: 5, page: 1 } }

            it 'returns paginated users sorted by last_login_at in asc order' do
              get_billable_members

              expect(Time.parse(json_response[0]["last_login_at"])).to be_like_time(user1.current_sign_in_at)
              expect_paginated_array_response(user1.id, user2.id, user3.id, user4.id)
            end
          end
        end
      end

      context 'with non owner' do
        it 'returns error' do
          get api(url, maintainer)

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when group can not be found' do
        let(:url) { "/groups/foo/billable_members" }

        it 'returns error' do
          get api(url, owner)

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('404 Group Not Found')
        end
      end

      context 'with non-root group' do
        let(:child_group) { create :group, parent: group }
        let(:url) { "/groups/#{child_group.id}/billable_members" }

        it 'returns error' do
          get_billable_members

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'email' do
        before do
          group.add_owner(owner)
        end

        include_context 'group managed account with group members'

        context 'when members have a public_email' do
          before do
            allow_next_found_instance_of(User) do |instance|
              allow(instance).to receive(:public_email).and_return('public@email.com')
            end
          end

          it { is_expected.to include(a_hash_including('email' => 'public@email.com')) }
        end

        context 'when members have no public_email' do
          it { is_expected.to include(a_hash_including('email' => nil)) }
        end
      end
    end

    describe 'GET /groups/:id/billable_members/:user_id/memberships', feature_category: :seat_cost_management do
      let_it_be(:developer) { create(:user) }
      let_it_be(:guest) { create(:user) }

      before_all do
        group.add_developer(developer)
        group.add_guest(guest)
      end

      it 'returns memberships for the billable group member' do
        membership = developer.members.first

        get api("/groups/#{group.id}/billable_members/#{developer.id}/memberships", owner)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq([{
          'id' => membership.id,
          'source_id' => group.id,
          'source_full_name' => group.full_name,
          'source_members_url' => group_group_members_url(group),
          'created_at' => membership.created_at.as_json,
          'expires_at' => nil,
          'access_level' => {
            'string_value' => 'Developer',
            'integer_value' => 30
          }
        }])
      end

      it 'returns not found when the user does not exist' do
        get api("/groups/#{group.id}/billable_members/#{non_existing_record_id}/memberships", owner)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response).to eq({ 'message' => '404 Not found' })
      end

      it 'returns not found when the group does not exist' do
        get api("/groups/#{non_existing_record_id}/billable_members/#{developer.id}/memberships", owner)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response).to eq({ 'message' => '404 Group Not Found' })
      end

      it 'returns not found when the user is not billable', :saas do
        create(:gitlab_subscription, :ultimate, namespace: group)

        get api("/groups/#{group.id}/billable_members/#{guest.id}/memberships", owner)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response).to eq({ 'message' => '404 User Not Found' })
      end

      it 'returns bad request if the user cannot admin group members' do
        get api("/groups/#{group.id}/billable_members/#{developer.id}/memberships", developer)

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'message' => '400 Bad request' })
      end

      it 'returns bad request if the group is a subgroup' do
        subgroup = create(:group, name: 'My SubGroup', parent: group)
        subgroup.add_developer(developer)

        get api("/groups/#{subgroup.id}/billable_members/#{developer.id}/memberships", owner)

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'message' => '400 Bad request' })
      end

      it 'excludes memberships outside the requested group hierarchy' do
        other_group = create(:group, name: 'My Other Group')
        other_group.add_developer(developer)

        get api("/groups/#{group.id}/billable_members/#{developer.id}/memberships", owner)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.map { |m| m['source_full_name'] }).to eq([group.full_name])
      end

      it 'includes subgroup memberships' do
        subgroup = create(:group, name: 'My SubGroup', parent: group)
        subgroup.add_developer(developer)

        get api("/groups/#{group.id}/billable_members/#{developer.id}/memberships", owner)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.map { |m| m['source_full_name'] }).to include(subgroup.full_name)
      end

      it 'includes project memberships' do
        project = create(:project, name: 'My Project', group: group)
        project.add_developer(developer)

        get api("/groups/#{group.id}/billable_members/#{developer.id}/memberships", owner)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.map { |m| m['source_full_name'] }).to include(project.full_name)
      end

      it 'paginates results' do
        subgroup = create(:group, name: 'SubGroup A', parent: group)
        subgroup.add_developer(developer)

        get api("/groups/#{group.id}/billable_members/#{developer.id}/memberships", owner), params: { page: 2, per_page: 1 }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.map { |m| m['source_full_name'] }).to eq([subgroup.full_name])
      end
    end

    describe 'PUT /groups/:id/members/:user_id/state', :saas do
      let(:url) { "/groups/#{group.id}/members/#{user.id}/state" }
      let(:state) { 'active' }
      let(:params) { { state: state } }

      let_it_be(:user) { create(:user) }

      subject(:change_state) { put api(url, current_user), params: params }

      context 'when the current user has insufficient rights' do
        let(:current_user) { create(:user) }

        it 'returns 400' do
          change_state

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when authenticated as an owner' do
        let(:current_user) { owner }

        context 'when setting the user to be active' do
          let(:state) { 'active' }

          it 'is successful' do
            member = create(:group_member, :awaiting, group: group, user: user)

            change_state

            expect(response).to have_gitlab_http_status(:success)
            expect(member.reload).to be_active
          end
        end

        context 'when setting the user to be awaiting' do
          let(:state) { 'awaiting' }

          it 'is successful' do
            member = create(:group_member, :active, group: group, user: user)

            change_state

            expect(response).to have_gitlab_http_status(:success)
            expect(member.reload).to be_awaiting
          end
        end

        it 'forwards the error from the service' do
          change_state

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['message']).to eq "No memberships found"
        end

        context 'with invalid parameters' do
          let(:state) { 'non-existing-state' }

          it 'returns a relevant error message' do
            change_state

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['error']).to eq 'state does not have a valid value'
          end
        end

        context 'with a group that does not exist' do
          let(:url) { "/groups/foo/members/#{user.id}/state" }

          it 'returns a relevant error message' do
            change_state

            expect(response).to have_gitlab_http_status(:not_found)
            expect(json_response['message']).to eq '404 Group Not Found'
          end
        end

        context 'with a group that is a sub-group' do
          let(:url) { "/groups/#{nested_group.id}/members/#{user.id}/state" }

          it 'returns a relevant error message' do
            change_state

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end

        context 'with a user that does not exist' do
          let(:url) { "/groups/#{group.id}/members/0/state" }

          it 'returns a relevant error message' do
            change_state

            expect(response).to have_gitlab_http_status(:not_found)
            expect(json_response['message']).to eq '404 User Not Found'
          end
        end

        context 'with a user that is not a member of the group' do
          it 'returns a relevant error message' do
            create(:group_member, :awaiting, group: create(:group), user: user)

            change_state

            expect(response).to have_gitlab_http_status(:unprocessable_entity)
            expect(json_response['message']).to eq "No memberships found"
          end
        end
      end
    end

    describe 'DELETE /groups/:id/billable_members/:user_id', feature_category: :seat_cost_management do
      context 'when the current user has insufficient rights' do
        it 'returns 400' do
          not_an_owner = create(:user)

          delete api("/groups/#{group.id}/billable_members/#{maintainer.id}", not_an_owner)

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      shared_examples 'successful deletion' do
        it 'deletes the member' do
          expect(group.member?(user)).to be is_group_member

          expect do
            delete api("/groups/#{group.id}/billable_members/#{user.id}", owner)

            expect(response).to have_gitlab_http_status(:no_content)
          end.to change { source.members.count }.by(-1)
        end
      end

      context 'when authenticated as an owner' do
        context 'with a user that is a GroupMember' do
          let(:user) { maintainer }
          let(:is_group_member) { true }
          let(:source) { group }

          it_behaves_like 'successful deletion'
        end

        context 'with a user that is only a ProjectMember' do
          let(:user) { create(:user) }
          let(:is_group_member) { false }
          let(:source) { project }
          let(:project) do
            create(:project, group: group) do |project|
              project.add_developer(user)
            end
          end

          it_behaves_like 'successful deletion'
        end

        context 'with a user that is not a member' do
          it 'returns a relevant error message' do
            user = create(:user)
            delete api("/groups/#{group.id}/billable_members/#{user.id}", owner)

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to eq '400 Bad request - No member found for the given user_id'
          end
        end
      end
    end
  end

  context 'without LDAP' do
    let(:group) { create(:group) }
    let(:owner) { create(:user) }
    let(:project) { create(:project, group: group) }

    before do
      group.add_owner(owner)
    end

    describe 'POST /projects/:id/members' do
      context 'group membership locked' do
        let(:user) { create(:user) }
        let(:group) { create(:group, membership_lock: true) }
        let(:project) { create(:project, group: group) }

        context 'project in a group' do
          it 'returns a 405 method not allowed error when group membership lock is enabled' do
            post api("/projects/#{project.id}/members", owner),
                 params: { user_id: user.id, access_level: Member::MAINTAINER }

            expect(response).to have_gitlab_http_status(:method_not_allowed)
          end
        end
      end
    end

    describe 'GET /groups/:id/members' do
      it 'matches json schema' do
        get api("/groups/#{group.to_param}/members", owner)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/members', dir: 'ee')
      end

      context 'when the flag gitlab_employee_badge is on and we are on gitlab.com' do
        it 'includes is_gitlab_employee in the response' do
          stub_feature_flags(gitlab_employee_badge: true)
          allow(Gitlab).to receive(:com?).and_return(true)

          get api("/groups/#{group.to_param}/members", owner)

          expect(json_response.first.keys).to include('is_gitlab_employee')
        end
      end

      context 'when the flag gitlab_employee_badge is off' do
        it 'does not include is_gitlab_employee in the response' do
          stub_feature_flags(gitlab_employee_badge: false)

          get api("/groups/#{group.to_param}/members", owner)

          expect(json_response.first.keys).not_to include('is_gitlab_employee')
        end
      end

      context 'when we are not on gitlab.com' do
        it 'does not include is_gitlab_employee in the response' do
          allow(Gitlab).to receive(:com?).and_return(false)

          get api("/groups/#{group.to_param}/members", owner)

          expect(json_response.first.keys).not_to include('is_gitlab_employee')
        end
      end

      context 'when a group has SAML provider configured' do
        let(:maintainer) { create(:user) }

        before do
          saml_provider = create :saml_provider, group: group
          create :group_saml_identity, user: owner, saml_provider: saml_provider

          group.add_maintainer(maintainer)
        end

        context 'and current_user is group owner' do
          it 'returns a list of users with group SAML identities info' do
            get api("/groups/#{group.to_param}/members", owner)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.size).to eq(2)
            expect(json_response.first['group_saml_identity']).to match(kind_of(Hash))
          end

          it 'allows to filter by linked identity presence' do
            get api("/groups/#{group.to_param}/members?with_saml_identity=true", owner)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.size).to eq(1)
            expect(json_response.any? { |member| member['id'] == maintainer.id }).to be_falsey
          end
        end

        context 'and current_user is not an owner' do
          it 'returns a list of users without group SAML identities info' do
            get api("/groups/#{group.to_param}/members", maintainer)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.map(&:keys).flatten).not_to include('group_saml_identity')
          end

          it 'ignores filter by linked identity presence' do
            get api("/groups/#{group.to_param}/members?with_saml_identity=true", maintainer)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.size).to eq(2)
            expect(json_response.any? { |member| member['id'] == maintainer.id }).to be_truthy
          end
        end
      end

      context 'with is_using_seat' do
        shared_examples 'seat information not included' do
          it 'returns a list of users that does not contain the is_using_seat attribute' do
            get api(api_url, owner)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.size).to eq(1)
            expect(json_response.first.keys).not_to include('is_using_seat')
          end
        end

        context 'with show_seat_info set to true' do
          it 'returns a list of users that contains the is_using_seat attribute' do
            get api("/groups/#{group.to_param}/members?show_seat_info=true", owner)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.size).to eq(1)
            expect(json_response.first['is_using_seat']).to be_truthy
          end
        end

        context 'with show_seat_info set to false' do
          let(:api_url) { "/groups/#{group.to_param}/members?show_seat_info=false" }

          it_behaves_like 'seat information not included'
        end

        context 'with no show_seat_info set' do
          let(:api_url) { "/groups/#{group.to_param}/members" }

          it_behaves_like 'seat information not included'
        end
      end
    end

    shared_examples 'POST /:source_type/:id/members' do |source_type|
      let(:stranger) { create(:user) }
      let(:url) { "/#{source_type.pluralize}/#{source.id}/members" }

      context "with :source_type == #{source_type.pluralize}" do
        it 'creates an audit event while creating a new member' do
          params = { user_id: stranger.id, access_level: Member::DEVELOPER }

          expect do
            post api(url, owner), params: params

            expect(response).to have_gitlab_http_status(:created)
          end.to change { AuditEvent.count }.by(1)
        end

        it 'does not create audit event if creating a new member fails' do
          params = { user_id: 0, access_level: Member::DEVELOPER }

          expect do
            post api(url, owner), params: params

            expect(response).to have_gitlab_http_status(:not_found)
          end.not_to change { AuditEvent.count }
        end
      end
    end

    it_behaves_like 'POST /:source_type/:id/members', 'project' do
      let(:source) { project }
    end

    it_behaves_like 'POST /:source_type/:id/members', 'group' do
      let(:source) { group }
    end
  end

  context 'group with LDAP group link' do
    include LdapHelpers

    let(:owner) { create(:user, username: 'owner_user') }
    let(:developer) { create(:user) }
    let(:ldap_developer) { create(:user) }
    let(:ldap_developer2) { create(:user) }

    let(:group) { create(:group_with_ldap_group_link, :public) }

    let!(:ldap_member) { create(:group_member, :developer, group: group, user: ldap_developer, ldap: true) }
    let!(:overridden_member) { create(:group_member, :developer, group: group, user: ldap_developer2, ldap: true, override: true) }
    let!(:regular_member) { create(:group_member, :developer, group: group, user: developer, ldap: false) }

    before do
      create(:group_member, :owner, group: group, user: owner)
      stub_ldap_setting(enabled: true)
    end

    describe 'GET /groups/:id/members/:user_id' do
      it 'does not contain an override attribute for non-LDAP users in the response' do
        get api("/groups/#{group.id}/members/#{developer.id}", owner)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(developer.id)
        expect(json_response['access_level']).to eq(Member::DEVELOPER)
        expect(json_response['override']).to eq(nil)
      end

      it 'contains an override attribute for ldap users in the response' do
        get api("/groups/#{group.id}/members/#{ldap_developer.id}", owner)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(ldap_developer.id)
        expect(json_response['access_level']).to eq(Member::DEVELOPER)
        expect(json_response['override']).to eq(false)
      end
    end

    describe 'PUT /groups/:id/members/:user_id' do
      it 'succeeds when access_level is modified after override has been set' do
        post api("/groups/#{group.id}/members/#{ldap_developer.id}/override", owner)
        expect(response).to have_gitlab_http_status(:created)

        put api("/groups/#{group.id}/members/#{ldap_developer.id}", owner),
            params: { access_level: Member::MAINTAINER }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(ldap_developer.id)
        expect(json_response['override']).to eq(true)
        expect(json_response['access_level']).to eq(Member::MAINTAINER)
      end

      it 'fails when access level is modified without an override' do
        put api("/groups/#{group.id}/members/#{ldap_developer.id}", owner),
            params: { access_level: Member::MAINTAINER }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    describe 'POST /groups/:id/members' do
      let(:stranger) { create(:user) }

      it 'returns a forbidden response' do
        post api("/groups/#{group.id}/members", owner),
             params: { user_id: stranger.id, access_level: Member::DEVELOPER }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    describe 'POST /groups/:id/members/:user_id/override' do
      it 'succeeds when override is set on an LDAP user' do
        post api("/groups/#{group.id}/members/#{ldap_developer.id}/override", owner)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['id']).to eq(ldap_developer.id)
        expect(json_response['override']).to eq(true)
        expect(json_response['access_level']).to eq(Member::DEVELOPER)
      end

      it 'fails when override is set for a non-ldap user' do
        post api("/groups/#{group.id}/members/#{developer.id}/override", owner)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    describe 'DELETE /groups/:id/members/:user_id/override with LDAP links' do
      it 'succeeds when override is already set on an LDAP user' do
        delete api("/groups/#{group.id}/members/#{ldap_developer2.id}/override", owner)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(ldap_developer2.id)
        expect(json_response['override']).to eq(false)
      end

      it 'returns 403 when override is set for a non-ldap user' do
        delete api("/groups/#{group.id}/members/#{developer.id}/override", owner)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  context 'group with pending members' do
    let_it_be(:owner) { create(:user, username: 'owner_user') }
    let_it_be(:developer) { create(:user) }
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:not_an_owner) { create(:user) }

    before do
      group.add_owner(owner)
    end

    describe 'PUT /groups/:id/members/:member_id/approve' do
      let_it_be(:member) { create(:group_member, :awaiting, group: group, user: developer) }

      let(:url) { "/groups/#{group.id}/members/#{member.id}/approve" }

      context 'with invalid params' do
        context 'when a subgroup is used' do
          let(:url) { "/groups/#{subgroup.id}/members/#{member.id}/approve" }

          it 'returns a bad request response' do
            put api(url, owner)

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end

        context 'when no group is found' do
          let(:url) { "/groups/#{non_existing_record_id}/members/#{member.id}/approve" }

          it 'returns a not found response' do
            put api(url, owner)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'when the current user does not have the :admin_group_member ability' do
        it 'returns a bad request response' do
          put api(url, not_an_owner)

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when the current user has permission to approve' do
        context 'when the member is not found' do
          let(:url) { "/groups/#{group.id}/members/#{non_existing_record_id}/approve" }

          it 'returns not found response' do
            put api(url, owner)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when the activation fails due to no pending members to activate' do
          let(:member) { create(:group_member, group: group) }

          it 'returns a bad request response' do
            put api(url, owner)

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end

        shared_examples 'successful activation' do
          it 'activates the member' do
            put api(url, owner)

            expect(response).to have_gitlab_http_status(:success)
            expect(member.reload.active?).to be true
          end
        end

        context 'when the member is a root group member' do
          it_behaves_like 'successful activation'
        end

        context 'when the member is a subgroup member' do
          let(:member) { create(:group_member, :awaiting, group: subgroup) }

          it_behaves_like 'successful activation'
        end

        context 'when the member is a project member' do
          let(:member) { create(:project_member, :awaiting, project: project) }

          it_behaves_like 'successful activation'
        end

        context 'when the member is an invited user' do
          let(:member) { create(:group_member, :awaiting, :invited, group: group) }

          it_behaves_like 'successful activation'
        end
      end
    end

    describe 'PUT /groups/:id/members/approve_all' do
      let(:url) { "/groups/#{group.id}/members/approve_all" }

      context 'when the current user is not authorized' do
        it 'returns a bad request response' do
          post api(url, not_an_owner)

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when the current user is authorized' do
        before do
          group.add_owner(owner)
        end

        context 'when the group ID is a subgroup' do
          let(:url) { "/groups/#{subgroup.id}/members/approve_all" }

          it 'returns a bad request response' do
            post api(url, owner)

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end

        context 'when params are valid' do
          it 'approves all pending members' do
            pending_group_member = create(:group_member, :awaiting, group: group)
            pending_subgroup_member = create(:group_member, :awaiting, group: subgroup)
            pending_project_member = create(:project_member, :awaiting, project: project)

            post api(url, owner)

            expect(response).to have_gitlab_http_status(:success)

            [pending_group_member, pending_subgroup_member, pending_subgroup_member, pending_project_member].each do |member|
              expect(member.reload.active?).to be true
            end
          end
        end

        context 'when activation fails' do
          it 'returns a bad request response' do
            allow_next_instance_of(::Members::ActivateService) do |service|
              allow(service).to receive(:execute).and_return({ status: :error })
            end

            post api(url, owner)

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end
    end

    describe 'GET /groups/:id/pending_members' do
      let(:url) { "/groups/#{group.id}/pending_members" }

      context 'when the current user is not authorized' do
        it 'returns a bad request response' do
          get api(url, not_an_owner)

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when the current user is authorized' do
        let_it_be(:pending_group_member) { create(:group_member, :awaiting, group: group) }
        let_it_be(:pending_subgroup_member) { create(:group_member, :awaiting, group: subgroup) }
        let_it_be(:pending_project_member) { create(:project_member, :awaiting, project: project) }
        let_it_be(:pending_invited_member) { create(:group_member, :awaiting, :invited, group: group) }

        it 'returns only pending members' do
          create(:group_member, group: group)

          get api(url, owner)

          expect(json_response.map { |m| m['id'] }).to match_array [
            pending_group_member.id,
            pending_subgroup_member.id,
            pending_project_member.id,
            pending_invited_member.id
          ]
        end

        it 'includes activated invited members' do
          pending_invited_member.activate!

          get api(url, owner)

          expect(json_response.map { |m| m['id'] }).to match_array [
            pending_group_member.id,
            pending_subgroup_member.id,
            pending_project_member.id,
            pending_invited_member.id
          ]
        end

        it 'returns only one membership per user' do
          create(:group_member, :awaiting, group: subgroup, user: pending_group_member.user)
          create(:group_member, :awaiting, :invited, group: subgroup, invite_email: pending_invited_member.invite_email)

          get api(url, owner)

          expect(json_response.map { |m| m['id'] }).to match_array [
            pending_group_member.id,
            pending_subgroup_member.id,
            pending_project_member.id,
            pending_invited_member.id
          ]
        end

        it 'paginates the response' do
          get api(url, owner)

          expect_paginated_array_response(*[
                                            pending_group_member.id,
                                            pending_subgroup_member.id,
                                            pending_project_member.id,
                                            pending_invited_member.id
                                          ])
        end

        context 'when the group ID is a subgroup' do
          let(:url) { "/groups/#{subgroup.id}/pending_members" }

          it 'returns a bad request response' do
            get api(url, owner)

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end
    end
  end

  context 'filtering project and group members' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:owner) { create(:user) }

    let(:params) { { state: state } }

    before do
      group.add_owner(owner)
    end

    subject do
      get api("/#{source_type}/#{source.id}/members/all", owner), params: params
      json_response
    end

    shared_examples 'filtered results' do
      context 'for active members' do
        let(:state) { 'active' }

        it 'returns only active members' do
          expect(subject.map { |u| u['id'] }).to match_array [active_member.user_id, owner.id]
        end
      end

      context 'for awaiting members' do
        let(:state) { 'awaiting' }

        it 'returns only awaiting members' do
          expect(subject.map { |u| u['id'] }).to match_array [awaiting_member.user_id]
        end
      end
    end

    context 'for group sources' do
      let(:source_type) { 'groups' }
      let(:source) { group }

      it_behaves_like 'filtered results' do
        let_it_be(:awaiting_member) { create(:group_member, :awaiting, group: group) }
        let_it_be(:active_member)   { create(:group_member, group: group) }
      end
    end

    context 'for project sources' do
      let(:source_type) { 'projects' }
      let(:source) { project }

      it_behaves_like 'filtered results' do
        let_it_be(:awaiting_member) { create(:project_member, :awaiting, project: project) }
        let_it_be(:active_member)   { create(:project_member, project: project) }
      end
    end
  end
end
