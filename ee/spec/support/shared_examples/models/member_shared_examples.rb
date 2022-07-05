# frozen_string_literal: true

RSpec.shared_examples 'member validations' do
  describe 'validations' do
    context 'validates SSO enforcement' do
      let(:user) { create(:user) }
      let(:identity) { create(:group_saml_identity, user: user) }
      let(:group) { identity.saml_provider.group }
      let(:entity) { group }

      context 'enforced SSO enabled' do
        before do
          allow_any_instance_of(SamlProvider).to receive(:enforced_sso?).and_return(true)
        end

        it 'allows adding a user linked to the SAML account as member' do
          member = entity.add_member(user, Member::DEVELOPER)

          expect(member).to be_valid
        end

        it 'does not allow adding a user not linked to the SAML account as member' do
          member = entity.add_member(create(:user), Member::DEVELOPER)

          expect(member).not_to be_valid
          expect(member.errors.messages[:user]).to eq(['is not linked to a SAML account'])
        end

        it 'allows adding a project bot as member' do
          member = entity.add_member(create(:user, :project_bot), Member::DEVELOPER)

          expect(member).to be_valid
        end

        context 'subgroups' do
          let!(:subgroup) { create(:group, parent: group) }

          before do
            entity.update!(group: subgroup) if entity.is_a?(Project)
          end

          it 'does not allow adding a group member with SSO enforced on subgroup' do
            member = entity.add_member(create(:user), ProjectMember::DEVELOPER)

            expect(member).not_to be_valid
            expect(member.errors.messages[:user]).to eq(['is not linked to a SAML account'])
          end
        end
      end

      context 'enforced SSO disabled' do
        it 'allows adding the group member' do
          member = entity.add_member(user, Member::DEVELOPER)

          expect(member).to be_valid
        end
      end
    end
  end
end

RSpec.shared_examples 'member group domain validations' do |source_type|
  context 'validates group domain limitations' do
    let(:group) { create(:group) }
    let(:gitlab_user) { create(:user, email: 'test@gitlab.com') }
    let(:gmail_user) { create(:user, email: 'test@gmail.com') }
    let(:unconfirmed_gitlab_user) { create(:user, :unconfirmed, email: 'unverified@gitlab.com') }
    let(:acme_user) { create(:user, email: 'user@acme.com') }

    before do
      create(:allowed_email_domain, group: group, domain: 'gitlab.com')
      create(:allowed_email_domain, group: group, domain: 'acme.com')
    end

    context 'when project parent has email domain feature switched on' do
      before do
        stub_licensed_features(group_allowed_email_domains: true)
      end

      it 'users email must match at least one of the allowed domain emails' do
        expect(build(member_type, source: source, user: gmail_user)).to be_invalid
        expect(build(member_type, source: source, user: gitlab_user)).to be_valid
        expect(build(member_type, source: source, user: acme_user)).to be_valid
      end

      it 'shows proper error message when not invited by admin' do
        member = build(member_type, source: source, user: gmail_user)
        allow(member).to receive_message_chain(:created_by, :can_admin_all_resources?).and_return(false)

        expect(member).to be_invalid
        expect(member.errors[:user]).to include("is not allowed for this #{source_type}. Check with your administrator.")
      end

      it 'shows proper error message when invited by admin' do
        member = build(member_type, source: source, user: gmail_user)
        allow(member).to receive_message_chain(:created_by, :can_admin_all_resources?).and_return(true)

        expect(member).to be_invalid
        expect(member.errors[:user]).to include("is not allowed for this #{source_type}. Go to the group’s &#39;Settings &gt; General&#39; page, and check &#39;Restrict membership by email domain&#39;.")
      end

      it 'shows proper error message for single domain limitation' do
        group.allowed_email_domains.last.destroy!
        member = build(member_type, source: source, user: gmail_user)

        expect(member).to be_invalid
        expect(member.errors[:user]).to include("is not allowed for this #{source_type}. Check with your administrator.")
      end

      it 'invited email must match at least one of the allowed domain emails' do
        expect(build(member_type, source: source, user: nil, invite_email: 'user@gmail.com')).to be_invalid
        expect(build(member_type, source: source, user: nil, invite_email: 'user@gitlab.com')).to be_valid
        expect(build(member_type, source: source, user: nil, invite_email: 'invite@acme.com')).to be_valid
      end

      it 'user emails matching allowed domain must be verified' do
        project_member = build(member_type, source: source, user: unconfirmed_gitlab_user)

        expect(project_member).to be_invalid
        expect(project_member.errors[:user]).to include("email 'unverified@gitlab.com' is not a verified email.")
      end

      context 'with project bot users' do
        let_it_be(:project_bot) { create(:user, :project_bot, email: "bot@example.com") }

        it 'bot user email does not match' do
          expect(group.allowed_email_domains.include?(project_bot.email)).to be_falsey
        end

        it 'allows the project bot user' do
          expect(build(member_type, source: source, user: project_bot)).to be_valid
        end
      end

      context 'with group SAML users' do
        let(:saml_provider) { create(:saml_provider, group: group) }

        let!(:group_related_identity) do
          create(:group_saml_identity, user: unconfirmed_gitlab_user, saml_provider: saml_provider)
        end

        it 'user emails does not have to be verified' do
          expect(build(member_type, source: source, user: unconfirmed_gitlab_user)).to be_valid
        end
      end

      context 'with group SCIM users' do
        let!(:scim_identity) do
          create(:scim_identity, user: unconfirmed_gitlab_user, group: group)
        end

        it 'user emails does not have to be verified' do
          expect(build(member_type, source: source, user: unconfirmed_gitlab_user)).to be_valid
        end
      end

      context 'when group is subgroup' do
        it 'users email must match at least one of the allowed domain emails' do
          expect(build(member_type, source: nested_source, user: gmail_user)).to be_invalid
          expect(build(member_type, source: nested_source, user: gitlab_user)).to be_valid
          expect(build(member_type, source: nested_source, user: acme_user)).to be_valid
        end

        it 'invited email must match at least one of the allowed domain emails' do
          expect(build(member_type, source: nested_source, user: nil, invite_email: 'user@gmail.com')).to be_invalid
          expect(build(member_type, source: nested_source, user: nil, invite_email: 'user@gitlab.com')).to be_valid
          expect(build(member_type, source: nested_source, user: nil, invite_email: 'invite@acme.com')).to be_valid
        end

        it 'user emails matching allowed domain must be verified' do
          member = build(member_type, source: nested_source, user: unconfirmed_gitlab_user)

          expect(member).to be_invalid
          expect(member.errors[:user]).to include("email 'unverified@gitlab.com' is not a verified email.")
        end

        context 'with group SCIM users' do
          let!(:scim_identity) do
            create(:scim_identity, user: unconfirmed_gitlab_user, group: group)
          end

          it 'user emails does not have to be verified' do
            expect(build(member_type, source: nested_source, user: unconfirmed_gitlab_user)).to be_valid
          end
        end

        context 'with group SAML users' do
          let(:saml_provider) { create(:saml_provider, group: group) }

          let!(:group_related_identity) do
            create(:group_saml_identity, user: unconfirmed_gitlab_user, saml_provider: saml_provider)
          end

          it 'user emails does not have to be verified' do
            expect(build(member_type, source: nested_source, user: unconfirmed_gitlab_user)).to be_valid
          end
        end
      end
    end

    context 'when project parent group has email domain feature switched off' do
      before do
        stub_licensed_features(group_allowed_email_domains: false)
      end

      it 'users email need not match allowed domain emails' do
        expect(build(member_type, source: source, user: gmail_user)).to be_valid
        expect(build(member_type, source: source, user: gitlab_user)).to be_valid
        expect(build(member_type, source: source, user: acme_user)).to be_valid
      end

      it 'invited email need not match allowed domain emails' do
        expect(build(member_type, source: source, invite_email: 'user@gmail.com')).to be_valid
        expect(build(member_type, source: source, invite_email: 'user@gitlab.com')).to be_valid
        expect(build(member_type, source: source, invite_email: 'user@acme.com')).to be_valid
      end

      it 'user emails does not have to be verified' do
        expect(build(member_type, source: source, user: unconfirmed_gitlab_user)).to be_valid
      end
    end
  end
end
