# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::UpdateService, '#execute', feature_category: :subgroups do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, :public) }

  context 'audit events' do
    let(:audit_event_params) do
      {
        author_id: user.id,
        entity_id: group.id,
        entity_type: 'Group',
        details: {
          author_name: user.name,
          author_class: user.class.name,
          target_id: group.id,
          target_type: 'Group',
          target_details: group.full_path
        }
      }
    end

    before do
      group.add_owner(user)
    end

    describe '#visibility' do
      include_examples 'audit event logging' do
        let(:fail_condition!) do
          allow(group).to receive(:save).and_return(false)
        end

        def operation
          update_group(group, user, visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        end

        let(:attributes) do
          audit_event_params.tap do |param|
            param[:details].merge!(
              change: 'visibility',
              from: 'Public',
              to: 'Private',
              custom_message: "Changed visibility from Public to Private"
            )
          end
        end
      end
    end

    describe 'ip restrictions' do
      context 'when IP restrictions were changed' do
        before do
          group.add_owner(user)
        end

        include_examples 'audit event logging' do
          let(:fail_condition!) do
            allow(group).to receive(:save).and_return(false)
          end

          def operation
            update_group(group, user, ip_restriction_ranges: '192.168.0.0/24,10.0.0.0/8' )
          end

          let(:attributes) do
            audit_event_params.tap do |param|
              param[:details].merge!(
                custom_message: "Group IP restrictions updated from '' to '192.168.0.0/24,10.0.0.0/8'"
              )
            end
          end
        end
      end
    end
  end

  context 'sub group' do
    let(:parent_group) { create :group }
    let(:group) { create :group, parent: parent_group }

    subject { update_group(group, user, { name: 'new_sub_group_name' }) }

    before do
      parent_group.add_owner(user)
    end

    include_examples 'sends streaming audit event'
  end

  describe 'changing file_template_project_id' do
    let(:group) { create(:group) }
    let(:valid_project) { create(:project, namespace: group) }
    let(:user) { create(:user) }

    def update_file_template_project_id(id)
      update_group(group, user, file_template_project_id: id)
    end

    before do
      stub_licensed_features(custom_file_templates_for_namespace: true)
    end

    context 'as a group maintainer' do
      before do
        group.add_maintainer(user)
      end

      it 'does not allow a project to be removed' do
        group.update_columns(file_template_project_id: valid_project.id)

        expect(update_file_template_project_id(nil)).to be_falsy
        expect(group.errors[:file_template_project_id]).to include('cannot be changed by you')
      end

      it 'does not allow a project to be set' do
        expect(update_file_template_project_id(valid_project.id)).to be_falsy
        expect(group.errors[:file_template_project_id]).to include('cannot be changed by you')
      end
    end

    context 'as a group owner' do
      before do
        group.add_owner(user)
      end

      it 'allows a project to be removed' do
        group.update_columns(file_template_project_id: valid_project.id)

        expect(update_file_template_project_id(nil)).to be_truthy
        expect(group.reload.file_template_project_id).to be_nil
      end

      it 'allows a valid project to be set' do
        expect(update_file_template_project_id(valid_project.id)).to be_truthy
        expect(group.reload.file_template_project_id).to eq(valid_project.id)
      end

      it 'does not allow a project outwith the group to be set' do
        invalid_project = create(:project)

        expect(update_file_template_project_id(invalid_project.id)).to be_falsy
        expect(group.errors[:file_template_project_id]).to include('is invalid')
      end

      it 'does not allow a non-existent project to be set' do
        invalid_project = create(:project)
        invalid_project.destroy!

        expect(update_file_template_project_id(invalid_project.id)).to be_falsy
        expect(group.errors[:file_template_project_id]).to include('is invalid')
      end

      context 'in a subgroup' do
        let(:parent_group) { create(:group) }
        let(:hidden_project) { create(:project, :private, namespace: parent_group) }
        let(:group) { create(:group, parent: parent_group) }

        before do
          group.update!(parent: parent_group)
        end

        it 'does not allow a project the group owner cannot see to be set' do
          expect(update_file_template_project_id(hidden_project.id)).to be_falsy
          expect(group.reload.file_template_project_id).to be_nil
        end

        it 'allows a project in the subgroup to be set' do
          expect(update_file_template_project_id(valid_project.id)).to be_truthy
          expect(group.reload.file_template_project_id).to eq(valid_project.id)
        end
      end
    end
  end

  context 'repository_size_limit assignment as Bytes' do
    let(:group) { create(:group, :public, repository_size_limit: 0) }

    context 'when param present' do
      let(:opts) { { repository_size_limit: '100' } }

      it 'converts from MB to Bytes' do
        update_group(group, user, opts)

        expect(group.reload.repository_size_limit).to eql(100 * 1024 * 1024)
      end
    end

    context 'when param not present' do
      let(:opts) { { repository_size_limit: '' } }

      it 'assign nil value' do
        update_group(group, user, opts)

        expect(group.reload.repository_size_limit).to be_nil
      end
    end
  end

  context 'setting ip_restriction' do
    let(:group) { create(:group) }

    subject { update_group(group, user, params) }

    before do
      stub_licensed_features(group_ip_restriction: true)
    end

    context 'when ip_restriction already exists' do
      let!(:ip_restriction) { IpRestriction.create!(group: group, range: '10.0.0.0/8') }

      context 'empty ip restriction param' do
        let(:params) { { ip_restriction_ranges: '' } }

        it 'deletes ip restriction' do
          expect(group.ip_restrictions.first.range).to eql('10.0.0.0/8')

          subject

          expect(group.reload.ip_restrictions.count).to eq(0)
        end
      end
    end
  end

  context 'setting allowed email domain' do
    let(:group) { create(:group, :private) }
    let(:user) { create(:user, email: 'admin@gitlab.com') }

    subject { update_group(group, user, params) }

    before do
      stub_licensed_features(group_allowed_email_domains: true)
    end

    context 'when allowed_email_domain already exists' do
      let!(:allowed_domain) { create(:allowed_email_domain, group: group, domain: 'gitlab.com') }

      context 'allowed_email_domains_list param is not specified' do
        let(:params) { {} }

        it 'does not call EE::AllowedEmailDomains::UpdateService#execute' do
          expect_any_instance_of(EE::AllowedEmailDomains::UpdateService).not_to receive(:execute)

          subject
        end
      end

      context 'allowed_email_domains_list param is blank' do
        let(:params) { { allowed_email_domains_list: '' } }

        context 'as a group owner' do
          before do
            group.add_owner(user)
          end

          it 'calls EE::AllowedEmailDomains::UpdateService#execute' do
            expect_any_instance_of(EE::AllowedEmailDomains::UpdateService).to receive(:execute)

            subject
          end

          it 'update is successful' do
            expect(subject).to eq(true)
          end

          it 'deletes existing allowed_email_domain record' do
            expect { subject }.to change { group.reload.allowed_email_domains.size }.from(1).to(0)
          end
        end

        context 'as a normal user' do
          it 'calls EE::AllowedEmailDomains::UpdateService#execute' do
            expect_any_instance_of(EE::AllowedEmailDomains::UpdateService).to receive(:execute)

            subject
          end

          it 'update is not successful' do
            expect(subject).to eq(false)
          end

          it 'registers an error' do
            subject

            expect(group.errors[:allowed_email_domains]).to include('cannot be changed by you')
          end

          it 'does not delete existing allowed_email_domain record' do
            expect { subject }.not_to change { group.reload.allowed_email_domains.size }
          end
        end
      end
    end
  end

  context 'updating protected params' do
    let(:attrs) { { shared_runners_minutes_limit: 1000, extra_shared_runners_minutes_limit: 100 } }

    context 'as an admin' do
      let(:user) { create(:admin) }

      it 'updates the attributes' do
        update_group(group, user, attrs)

        expect(group.shared_runners_minutes_limit).to eq(1000)
        expect(group.extra_shared_runners_minutes_limit).to eq(100)
      end
    end

    context 'as a regular user' do
      it 'ignores the attributes' do
        update_group(group, user, attrs)

        expect(group.shared_runners_minutes_limit).to be_nil
        expect(group.extra_shared_runners_minutes_limit).to be_nil
      end
    end
  end

  context 'updating insight_attributes.project_id param' do
    let(:attrs) { { insight_attributes: { project_id: private_project.id } } }

    shared_examples 'successful update of the Insights project' do
      it 'updates the Insights project' do
        update_group(group, user, attrs)

        expect(group.insight.project).to eq(private_project)
      end
    end

    shared_examples 'ignorance of the Insights project ID' do
      it 'ignores the Insights project ID' do
        update_group(group, user, attrs)

        expect(group.insight).to be_nil
      end
    end

    context 'when project is not in the group' do
      let(:private_project) { create(:project, :private) }

      context 'when user can read the project' do
        before do
          private_project.add_maintainer(user)
        end

        it_behaves_like 'ignorance of the Insights project ID'
      end

      context 'when user cannot read the project' do
        it_behaves_like 'ignorance of the Insights project ID'
      end
    end

    context 'when project is in the group' do
      let(:private_project) { create(:project, :private, group: group) }

      context 'when user can read the project' do
        before do
          private_project.add_maintainer(user)
        end

        it_behaves_like 'successful update of the Insights project'
      end

      context 'when user cannot read the project' do
        it_behaves_like 'ignorance of the Insights project ID'
      end
    end
  end

  context 'updating analytics_dashboards_pointer_attributes.target_project_id param' do
    let(:attrs) { { analytics_dashboards_pointer_attributes: { target_project_id: private_project.id } } }
    let(:private_project) do
      create(:project, :private).tap do |project|
        project.add_maintainer(user)
      end
    end

    it 'updates the Analytics Dashboards pointer project' do
      update_group(group, user, attrs)

      expect(group.analytics_dashboards_pointer.target_project).to eq(private_project)
    end

    context 'when pointer project is empty' do
      let(:existing_pointer) do
        create(:analytics_dashboards_pointer, namespace: group, target_project: private_project)
      end

      let(:attrs) { { analytics_dashboards_pointer_attributes: { id: existing_pointer.id, target_project_id: '' } } }

      it 'removes pointer project' do
        update_group(group, user, attrs)

        expect(group.reload.analytics_dashboards_pointer).to eq(nil)
      end
    end
  end

  context 'updating `max_personal_access_token_lifetime` param' do
    subject { update_group(group, user, attrs) }

    let!(:group) do
      create(:group_with_managed_accounts, :public, max_personal_access_token_lifetime: 1)
    end

    let(:limit) { 10 }
    let(:attrs) { { max_personal_access_token_lifetime: limit } }

    shared_examples_for 'it does not call the update lifetime service' do
      it "doesn't call the update lifetime service" do
        expect(::PersonalAccessTokens::Groups::UpdateLifetimeService).not_to receive(:new)

        subject
      end
    end

    it 'updates the attribute' do
      expect { subject }.to change { group.reload.max_personal_access_token_lifetime }.from(1).to(10)
    end

    context 'when the group does not enforce managed accounts' do
      it_behaves_like 'it does not call the update lifetime service'
    end

    context 'when the group enforces managed accounts' do
      before do
        allow(group).to receive(:enforced_group_managed_accounts?).and_return(true)
      end

      context 'without `personal_access_token_expiration_policy` licensed' do
        before do
          stub_licensed_features(personal_access_token_expiration_policy: false)
        end

        it_behaves_like 'it does not call the update lifetime service'
      end

      context 'with personal_access_token_expiration_policy licensed' do
        before do
          stub_licensed_features(personal_access_token_expiration_policy: true)
        end

        context 'when `max_personal_access_token_lifetime` is updated to null value' do
          let(:limit) { nil }

          it_behaves_like 'it does not call the update lifetime service'
        end

        context 'when `max_personal_access_token_lifetime` is updated to a non-null value' do
          it 'executes the update lifetime service' do
            expect_next_instance_of(::PersonalAccessTokens::Groups::UpdateLifetimeService, group) do |service|
              expect(service).to receive(:execute)
            end

            subject
          end
        end
      end
    end
  end

  def update_group(group, user, opts)
    Groups::UpdateService.new(group, user, opts).execute
  end
end
