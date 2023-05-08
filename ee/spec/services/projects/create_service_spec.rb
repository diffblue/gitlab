# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::CreateService, '#execute' do
  include EE::GeoHelpers

  let(:user) { create :user }
  let(:opts) do
    {
      name: "GitLab",
      namespace_id: user.namespace.id
    }
  end

  context 'with a built-in template' do
    before do
      opts.merge!(
        template_name: 'rails'
      )
    end

    it 'creates a project using the template service' do
      expect(::Projects::CreateFromTemplateService).to receive_message_chain(:new, :execute)

      create_project(user, opts)
    end
  end

  context 'with a template project ID' do
    before do
      opts.merge!(
        template_project_id: 1
      )
    end

    it 'creates a project using the template service' do
      expect(::Projects::CreateFromTemplateService).to receive_message_chain(:new, :execute)

      create_project(user, opts)
    end
  end

  context 'with import_type gitlab_custom_project_template' do
    let(:group) do
      create(:group, project_creation_level: project_creation_level).tap do |group|
        group.add_developer(user)
      end
    end

    let(:opts) do
      {
        name: 'GitLab',
        namespace_id: group.id,
        import_type: 'gitlab_custom_project_template',
        import_data: {
          data: {
            template_project_id: 1
          }
        }
      }
    end

    before do
      stub_licensed_features(custom_project_templates: true)
    end

    context 'when the user is allowed to create projects within the namespace' do
      let(:project_creation_level) { Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS }

      it 'creates a project' do
        project = create_project(user, opts)

        expect(project).to be_persisted
        expect(project.import_type).to eq('gitlab_custom_project_template')
      end
    end

    context 'when the user is not allowed to create projects within the namespace' do
      let(:project_creation_level) { Gitlab::Access::MAINTAINER_PROJECT_ACCESS }

      it 'does not create a project' do
        project = create_project(user, opts)

        expect(project).not_to be_persisted
      end
    end
  end

  context 'with a CI/CD only project' do
    before do
      opts.merge!(
        ci_cd_only: true,
        import_url: 'http://foo.com'
      )
    end

    context 'when CI/CD projects feature is available' do
      before do
        stub_licensed_features(ci_cd_projects: true)
      end

      it 'calls the service to set up CI/CD on the project' do
        expect(CiCd::SetupProject).to receive_message_chain(:new, :execute)

        create_project(user, opts)
      end
    end

    context 'when CI/CD projects feature is not available' do
      before do
        stub_licensed_features(ci_cd_projects: false)
      end

      it "doesn't call the service to set up CI/CD on the project" do
        expect(CiCd::SetupProject).not_to receive(:new)

        create_project(user, opts)
      end
    end
  end

  context 'repository_size_limit assignment as Bytes' do
    let(:admin_user) { create(:user, admin: true) }

    context 'when param present' do
      let(:opts) { { repository_size_limit: '100' } }

      it 'assign repository_size_limit as Bytes' do
        project = create_project(admin_user, opts)

        expect(project.repository_size_limit).to eql(100 * 1024 * 1024)
      end
    end

    context 'when param not present' do
      let(:opts) { { repository_size_limit: '' } }

      it 'assign nil value' do
        project = create_project(admin_user, opts)

        expect(project.repository_size_limit).to be_nil
      end
    end
  end

  context 'without repository mirror' do
    before do
      stub_licensed_features(repository_mirrors: true)
      opts.merge!(import_url: 'http://foo.com')
    end

    it 'sets the mirror to false' do
      project = create_project(user, opts)

      expect(project).to be_persisted
      expect(project.mirror).to be false
    end
  end

  context 'with repository mirror' do
    before do
      opts.merge!(import_url: 'http://foo.com', mirror: true)
    end

    context 'when licensed' do
      before do
        stub_licensed_features(repository_mirrors: true)
      end

      it 'sets the correct attributes' do
        project = create_project(user, opts)

        expect(project).to be_persisted
        expect(project.mirror).to be true
        expect(project.mirror_user_id).to eq(user.id)
      end

      context 'with mirror trigger builds' do
        before do
          opts.merge!(mirror_trigger_builds: true)
        end

        it 'sets the mirror trigger builds' do
          project = create_project(user, opts)

          expect(project).to be_persisted
          expect(project.mirror_trigger_builds).to be true
        end
      end

      context 'with checks on the namespace' do
        before do
          enable_namespace_license_check!
        end

        context 'when not licensed on a namespace' do
          it 'does not allow enabeling mirrors' do
            project = create_project(user, opts)

            expect(project).to be_persisted
            expect(project.mirror).to be_falsey
          end
        end

        context 'when licensed on a namespace', :saas do
          it 'allows enabling mirrors' do
            create(:gitlab_subscription, :ultimate, namespace: user.namespace)

            project = create_project(user, opts)

            expect(project).to be_persisted
            expect(project.mirror).to be_truthy
          end
        end
      end
    end

    context 'when unlicensed' do
      before do
        stub_licensed_features(repository_mirrors: false)
      end

      it 'does not set mirror attributes' do
        project = create_project(user, opts)

        expect(project).to be_persisted
        expect(project.mirror).to be false
        expect(project.mirror_user_id).to be_nil
      end

      context 'with mirror trigger builds' do
        before do
          opts.merge!(mirror_trigger_builds: true)
        end

        it 'sets the mirror trigger builds' do
          project = create_project(user, opts)

          expect(project).to be_persisted
          expect(project.mirror_trigger_builds).to be false
        end
      end
    end
  end

  context 'when inherited_push_rule_for_project is disabled' do
    before do
      stub_feature_flags(inherited_push_rule_for_project: false)
    end

    context 'with sample' do
      let!(:sample) { create(:push_rule_sample) }

      before do
        stub_licensed_features(push_rules: true)
      end

      subject(:push_rule) { create_project(user, opts).push_rule }

      it 'creates push rule from sample' do
        is_expected.to have_attributes(
          force_push_regex: sample.force_push_regex,
          deny_delete_tag: sample.deny_delete_tag,
          delete_branch_regex: sample.delete_branch_regex,
          commit_message_regex: sample.commit_message_regex
        )
      end

      it 'creates association between project settings and push rule' do
        project_setting = subject.project.project_setting

        expect(project_setting.push_rule_id).to eq(subject.id)
      end

      context 'push rules unlicensed' do
        before do
          stub_licensed_features(push_rules: false)
        end

        subject(:push_rule) { create_project(user, opts).push_rule }

        it 'ignores the push rule sample' do
          is_expected.to be_nil
        end
      end
    end

    context 'when there are no push rules' do
      it 'does not create push rule' do
        expect(create_project(user, opts).push_rule).to be_nil
      end
    end
  end

  context 'group push rules' do
    before do
      stub_licensed_features(push_rules: true)
      stub_feature_flags(inherited_push_rule_for_project: false)
    end

    context 'project created within a group' do
      let(:group) { create(:group) }
      let(:sub_group) { create(:group, parent: group) }
      let(:opts) do
        {
          name: "GitLab",
          namespace_id: group.id
        }
      end

      before do
        group.add_owner(user)
      end

      context 'when group has push rule defined' do
        let(:group_push_rule) { create(:push_rule_without_project, force_push_regex: 'testing me') }

        before do
          group.update!(push_rule: group_push_rule)
        end

        it 'does not error if new columns are created since the last schema load' do
          PushRule.connection.execute('ALTER TABLE push_rules ADD COLUMN foobar boolean')

          project = create_project(user, opts)

          project_push_rule = project.push_rule
          expect(project_push_rule).to be_persisted
        end

        it 'creates push rule from group push rule' do
          project = create_project(user, opts)
          project_push_rule = project.push_rule

          expect(project_push_rule).to have_attributes(
            force_push_regex: group_push_rule.force_push_regex,
            deny_delete_tag: group_push_rule.deny_delete_tag,
            delete_branch_regex: group_push_rule.delete_branch_regex,
            commit_message_regex: group_push_rule.commit_message_regex,
            is_sample: false
          )
          expect(project.project_setting.push_rule_id).to eq(project_push_rule.id)
        end

        it 'within sub_group creates push rule from group push rule' do
          project = create_project(user, opts.merge(namespace_id: sub_group.id))
          project_push_rule = project.push_rule

          expect(project_push_rule).to have_attributes(
            force_push_regex: group_push_rule.force_push_regex,
            deny_delete_tag: group_push_rule.deny_delete_tag,
            delete_branch_regex: group_push_rule.delete_branch_regex,
            commit_message_regex: group_push_rule.commit_message_regex,
            is_sample: false
          )
          expect(project.project_setting.push_rule_id).to eq(project_push_rule.id)
        end
      end

      context 'when group does not have push rule defined' do
        let!(:sample) { create(:push_rule_sample) }

        it 'creates push rule from sample' do
          expect(create_project(user, opts).push_rule).to have_attributes(
            force_push_regex: sample.force_push_regex,
            deny_delete_tag: sample.deny_delete_tag,
            delete_branch_regex: sample.delete_branch_regex,
            commit_message_regex: sample.commit_message_regex
          )
        end

        it 'creates push rule from sample in sub-group' do
          expect(create_project(user, opts.merge(namespace_id: sub_group.id)).push_rule).to have_attributes(
            force_push_regex: sample.force_push_regex,
            deny_delete_tag: sample.deny_delete_tag,
            delete_branch_regex: sample.delete_branch_regex,
            commit_message_regex: sample.commit_message_regex
          )
        end
      end
    end
  end

  context 'when running on a primary node' do
    let_it_be(:primary) { create(:geo_node, :primary) }
    let_it_be(:secondary) { create(:geo_node) }

    before do
      stub_current_geo_node(primary)
    end

    it 'logs an event to the Geo event log' do
      expect { create_project(user, opts) }.to change(Geo::RepositoryCreatedEvent, :count).by(1)
    end

    it 'does not log event to the Geo log if project creation fails' do
      failing_opts = {
        name: nil,
        namespace: user.namespace
      }

      expect { create_project(user, failing_opts) }.not_to change(Geo::RepositoryCreatedEvent, :count)
    end
  end

  context 'when importing Project by repo URL' do
    context 'and check namespace plan is enabled' do
      before do
        allow_next_instance_of(EE::Project) do |instance|
          allow(instance).to receive(:add_import_job)
        end
        enable_namespace_license_check!
      end

      it 'creates the project' do
        opts = {
          name: 'GitLab',
          import_url: 'https://www.gitlab.com/gitlab-org/gitlab-foss',
          visibility_level: Gitlab::VisibilityLevel::PRIVATE,
          namespace_id: user.namespace.id,
          mirror: true,
          mirror_trigger_builds: true
        }

        project = create_project(user, opts)

        expect(project).to be_persisted
      end
    end
  end

  context 'audit events' do
    include_examples 'audit event logging' do
      let_it_be(:user) { create(:user) }
      let(:operation) { create_project(user, opts) }
      let(:fail_condition!) do
        allow(Gitlab::VisibilityLevel).to receive(:allowed_for?).and_return(false)
      end

      let(:event_type) { Projects::CreateService::AUDIT_EVENT_TYPE }

      let(:attributes) do
        {
           author_id: user.id,
           entity_id: @resource.id,
           entity_type: 'Project',
           details: {
             author_name: user.name,
             target_id: @resource.id,
             target_type: 'Project',
             target_details: @resource.full_path,
             custom_message: Projects::CreateService::AUDIT_EVENT_MESSAGE,
             author_class: user.class.name
           }
         }
      end
    end
  end

  context 'security policy configuration' do
    context 'with security_policy_target_project_id' do
      let_it_be(:security_policy_target_project) { create(:project) }

      before do
        opts[:security_policy_target_project_id] = security_policy_target_project.id

        stub_licensed_features(security_orchestration_policies: true)
      end

      it 'creates security policy configuration for the project' do
        expect(::Security::Orchestration::AssignService).to receive_message_chain(:new, :execute)

        create_project(user, opts)
      end
    end

    context 'with security_policy_target_namespace_id' do
      let_it_be(:security_policy_target_namespace) { create(:namespace) }

      before do
        opts[:security_policy_target_namespace_id] = security_policy_target_namespace.id

        stub_licensed_features(security_orchestration_policies: true)
      end

      it 'creates security policy configuration for the project' do
        expect(::Security::Orchestration::AssignService).to receive_message_chain(:new, :execute)

        create_project(user, opts)
      end
    end
  end

  describe 'after create actions' do
    describe 'set_default_compliance_framework' do
      let_it_be(:admin_bot) { create(:user, :admin_bot, :admin) }
      let_it_be(:group, reload: true) { create(:group) }
      let_it_be(:framework) { create(:compliance_framework, namespace: group, name: 'GDPR') }
      let_it_be(:framework_two) { create(:compliance_framework, namespace: group, name: 'HIPAA') }

      context 'when default compliance framework is set at the root namespace' do
        before do
          group.add_owner(user)
          group.add_owner(admin_bot)
          group.namespace_settings.update!(default_compliance_framework_id: framework.id)
        end

        it 'sets the default compliance framework for new projects when licensed', :sidekiq_inline do
          stub_licensed_features(custom_compliance_frameworks: true, compliance_framework: true)

          expect(::ComplianceManagement::UpdateDefaultFrameworkWorker).to receive(:perform_async).with(
            user.id,
            anything,
            framework.id
          ).and_call_original

          project = create_project(user, { name: "GitLab", namespace_id: group.id })

          expect(project.compliance_management_framework.id).to eq(framework.id)
          expect(project.compliance_management_framework.name).to eq('GDPR')
        end

        it 'does not set the default compliance framework for new projects when not licensed' do
          expect(::ComplianceManagement::UpdateDefaultFrameworkWorker).not_to receive(:perform_async)

          project = create_project(user, { name: "GitLab", namespace_id: group.id })

          expect(project.compliance_framework_setting).to eq(nil)
        end
      end

      context 'when default compliance framework is not set at the root namespace' do
        before do
          group.add_owner(user)
          group.add_owner(admin_bot)
          group.namespace_settings.update!(default_compliance_framework_id: nil)
        end

        it 'does not set the default compliance framework for new projects' do
          stub_licensed_features(custom_compliance_frameworks: true, compliance_framework: true)

          expect(::ComplianceManagement::UpdateDefaultFrameworkWorker).not_to receive(:perform_async)

          project = create_project(user, { name: "GitLab", namespace_id: group.id })

          expect(project.compliance_framework_setting).to eq(nil)
        end
      end

      context 'when project belongs to a user namespace' do
        it 'does not set the default compliance framework for new projects' do
          stub_licensed_features(custom_compliance_frameworks: true, compliance_framework: true)

          expect(::ComplianceManagement::UpdateDefaultFrameworkWorker).not_to receive(:perform_async)

          project = create_project(user, opts)

          expect(project.compliance_framework_setting).to eq(nil)
        end
      end
    end

    describe 'sync scan result policies from group' do
      let_it_be(:group, reload: true) { create(:group) }
      let_it_be(:sub_group, reload: true) { create(:group, parent: group) }

      before do
        group.add_owner(user)
      end

      context 'when group has security_orchestration_policy_configuration' do
        let(:policy) { build(:scan_result_policy, branches: []) }
        let_it_be(:group_configuration, reload: true) do
          create(:security_orchestration_policy_configuration, project: nil, namespace: group)
        end

        let_it_be(:sub_group_configuration, reload: true) do
          create(:security_orchestration_policy_configuration, project: nil, namespace: sub_group)
        end

        before do
          allow_next_found_instance_of(Security::OrchestrationPolicyConfiguration) do |configuration|
            allow(configuration).to receive(:policy_last_updated_by).and_return(user)
          end

          allow_next_instance_of(Repository) do |repository|
            allow(repository).to receive(:blob_data_at).and_return({ scan_result_policy: [policy] }.to_yaml)
          end
        end

        it 'invokes ProcessScanResultPolicyWorker', :sidekiq_inline do
          expect(::Security::ProcessScanResultPolicyWorker).to receive(:perform_async).twice.and_call_original

          project = create_project(user, name: "GitLab", namespace_id: sub_group.id)

          expect(project.approval_rules.count).to eq(2)
          expect(project.approval_rules.map(&:security_orchestration_policy_configuration_id)).to match_array([
            group_configuration.id, sub_group_configuration.id
          ])
        end
      end

      context 'when group does not have security_orchestration_policy_configuration' do
        it 'does not invoke ProcessScanResultPolicyWorker' do
          expect(::Security::ProcessScanResultPolicyWorker).not_to receive(:perform_async)

          create_project(user, { name: "GitLab", namespace_id: sub_group.id })
        end
      end
    end
  end

  def create_project(user, opts)
    described_class.new(user, opts).execute
  end
end
