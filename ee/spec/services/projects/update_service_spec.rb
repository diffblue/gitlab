# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::UpdateService, '#execute', feature_category: :projects do
  include EE::GeoHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:user, :admin) }
  let(:project) { create(:project, :repository, creator: user, namespace: user.namespace) }

  context 'shared runners', :saas do
    let(:user) { create(:user) }
    let(:opts) { { shared_runners_enabled: enabled } }
    let(:enabled) { true }

    before do
      create(:gitlab_subscription, namespace: user.namespace, hosted_plan: create(:free_plan))
      allow(::Gitlab).to receive(:com?).and_return(true)
    end

    context 'when shared runners are on' do
      let(:enabled) { false }

      before do
        project.update!(shared_runners_enabled: true)
      end

      it 'disables shared runners', :aggregate_failures do
        result = update_project(project, user, opts)

        expect(result).to eq(status: :success)
        expect(project).to have_attributes(opts)
      end

      context 'when user has valid credit card' do
        before do
          create(:credit_card_validation, user: user)
        end

        it 'disables shared runners', :aggregate_failures do
          result = update_project(project, user, opts)

          expect(result).to eq(status: :success)
          expect(project).to have_attributes(opts)
        end
      end
    end

    context 'when shared runners are off' do
      before do
        project.update!(shared_runners_enabled: false)
      end

      context 'when user has valid credit card' do
        before do
          create(:credit_card_validation, user: user)
        end

        it 'enables shared runners', :aggregate_failures do
          result = update_project(project, user, opts)

          expect(result).to eq(status: :success)
          expect(project).to have_attributes(opts)
        end
      end

      context 'when user does not have valid credit card' do
        it 'does not enable shared runners', :aggregate_failures do
          result = update_project(project, user, opts)

          project.reload

          expect(result).to eq(status: :error, message: 'Shared runners enabled cannot be enabled until a valid credit card is on file')
          expect(project.shared_runners_enabled).to eq(false)
        end
      end
    end
  end

  context 'repository mirror' do
    let(:opts) { { mirror: true, import_url: 'http://foo.com' } }

    before do
      stub_licensed_features(repository_mirrors: true)
    end

    it 'sets mirror attributes' do
      result = update_project(project, user, opts)

      expect(result).to eq(status: :success)
      expect(project).to have_attributes(opts)
      expect(project.mirror_user).to eq(user)
    end

    it 'does not touch mirror_user_id for non-mirror changes' do
      result = update_project(project, user, description: 'anything')

      expect(result).to eq(status: :success)
      expect(project.mirror_user).to be_nil
    end

    it 'forbids non-admins from setting mirror_user_id explicitly' do
      project.team.add_maintainer(admin)
      result = update_project(project, user, opts.merge(mirror_user_id: admin.id))

      expect(result).to eq(status: :error, message: 'Mirror user is invalid')
      expect(project.mirror_user).to be_nil
    end

    it 'allows admins to set mirror_user_id' do
      project.team.add_maintainer(admin)
      result = update_project(project, admin, opts.merge(mirror_user_id: user.id))

      expect(result).to eq(status: :success)
      expect(project.mirror_user).to eq(user)
    end

    it 'forces an import job' do
      expect_any_instance_of(EE::ProjectImportState).to receive(:force_import_job!).once

      update_project(project, user, opts)
    end

    context 'when update mirror branch setting' do
      before do
        project.team.add_maintainer(admin)
      end

      it 'allow mirror_branch_regex to be updated' do
        result = update_project(project, admin, opts.merge(mirror_branch_regex: :test))

        expect(result).to eq(status: :success)
        expect(project.mirror_branch_regex).to match('test')
      end

      it 'enable only_mirror_protected_branches would clean mirror_branch_regex' do
        project.mirror_branch_regex = 'test'
        result = update_project(project, admin, opts.merge(only_mirror_protected_branches: true))

        expect(result).to eq(status: :success)
        expect(project.mirror_branch_regex).to be_nil
      end

      it 'fill mirror_branch_regex would disable only_mirror_protected_branches' do
        project.only_mirror_protected_branches = true
        result = update_project(project, admin, opts.merge(mirror_branch_regex: 'text'))

        expect(result).to eq(status: :success)
        expect(project.only_mirror_protected_branches).to be_falsey
      end

      context 'when `mirror_only_branches_match_regex` FF is disabled' do
        before do
          stub_feature_flags(mirror_only_branches_match_regex: false)
        end

        it 'ignores mirror_branch_regex parameter' do
          result = update_project(project, admin, opts.merge(mirror_branch_regex: 'text'))

          expect(result).to eq(status: :success)
          expect(project.mirror_branch_regex).to be_nil
        end
      end
    end
  end

  context 'audit events' do
    let_it_be(:user) { create(:user) }

    let(:audit_event_params) do
      {
        author_id: user.id,
        entity_id: project.id,
        entity_type: 'Project',
        details: {
          author_name: user.name,
          author_class: user.class.name,
          target_id: project.id,
          target_type: 'Project',
          target_details: project.full_path
        }
      }
    end

    describe '#name' do
      include_examples 'audit event logging' do
        let!(:old_name) { project.full_name }
        let(:fail_condition!) do
          allow_any_instance_of(Project).to receive(:update).and_return(false)
        end

        def operation
          update_project(project, user, name: 'foobar')
        end

        let(:attributes) do
          audit_event_params.tap do |param|
            param[:details].merge!(
              change: 'name',
              from: old_name,
              to: project.full_name,
              custom_message: "Changed name from #{old_name} to #{project.full_name}"
            )
          end
        end
      end
    end

    describe '#path' do
      include_examples 'audit event logging' do
        let(:fail_condition!) do
          allow_any_instance_of(Project).to receive(:update).and_return(false)
        end

        def operation
          update_project(project, user, path: 'foobar1')
        end

        let(:attributes) do
          audit_event_params.tap do |param|
            param[:details].merge!(
              change: 'path',
              from: project.old_path_with_namespace,
              to: project.full_path,
              custom_message: "Changed path from #{project.old_path_with_namespace} to #{project.full_path}"
            )
          end
        end
      end
    end

    describe '#default_branch' do
      include_examples 'audit event logging' do
        let(:fail_condition!) do
          allow_next_instance_of(Project) do |project|
            allow(project).to receive(:change_head).and_return(false)
          end
        end

        def operation
          update_project(project, user, default_branch: 'feature')
        end

        let_it_be(:event_type) { Projects::UpdateService::DEFAULT_BRANCH_CHANGE_AUDIT_TYPE }

        let(:attributes) do
          audit_event_params.tap do |param|
            param[:details].merge!(
              from: project.previous_default_branch,
              to: project.default_branch,
              custom_message: format(Projects::UpdateService::DEFAULT_BRANCH_CHANGE_AUDIT_MESSAGE, project.previous_default_branch, project.default_branch)
            )
          end
        end
      end
    end

    describe '#visibility' do
      include_examples 'audit event logging' do
        let(:fail_condition!) do
          allow_any_instance_of(Project).to receive(:update).and_return(false)
        end

        def operation
          update_project(project, user, visibility_level: Gitlab::VisibilityLevel::INTERNAL)
        end

        let(:attributes) do
          audit_event_params.tap do |param|
            param[:details].merge!(
              change: 'visibility_level',
              from: 'Private',
              to: 'Internal',
              custom_message: "Changed visibility_level from Private to Internal"
            )
          end
        end
      end
    end
  end

  context 'triggering wiki Geo syncs', :geo, feature_category: :geo_replication do
    context 'with geo_project_wiki_repository_replication feature flag disabled' do
      before do
        stub_feature_flags(geo_project_wiki_repository_replication: false)
      end

      context 'when on a Geo primary site' do
        let_it_be(:primary) { create(:geo_node, :primary) }
        let_it_be(:secondary) { create(:geo_node) }

        before do
          stub_current_geo_node(primary)
        end

        context 'when enabling a wiki' do
          it 'creates a RepositoryUpdatedEvent' do
            project.project_feature.update_column(:wiki_access_level, ProjectFeature::DISABLED)
            project.reload

            expect do
              result = update_project(project, user, project_feature_attributes: { wiki_access_level: ProjectFeature::ENABLED })
              expect(result).to eq({ status: :success })
            end.to change { Geo::RepositoryUpdatedEvent.count }.by(1)

            expect(project.wiki_enabled?).to be true
          end
        end

        context 'when we update project but not enabling a wiki' do
          context 'when the wiki is disabled' do
            it 'does not create a RepositoryUpdatedEvent' do
              project.project_feature.update_column(:wiki_access_level, ProjectFeature::DISABLED)

              expect do
                result = update_project(project, user, { name: 'test1' })
                expect(result).to eq({ status: :success })
              end.not_to change { Geo::RepositoryUpdatedEvent.count }

              expect(project.wiki_enabled?).to be false
            end
          end

          context 'when the wiki was already enabled' do
            it 'does not create a RepositoryUpdatedEvent' do
              project.project_feature.update_column(:wiki_access_level, ProjectFeature::ENABLED)

              expect do
                result = update_project(project, user, { name: 'test1' })
                expect(result).to eq({ status: :success })
              end.not_to change { Geo::RepositoryUpdatedEvent.count }

              expect(project.wiki_enabled?).to be true
            end
          end
        end
      end

      context 'when not on a Geo primary site' do
        it 'does not create a RepositoryUpdatedEvent when enabling a wiki' do
          project.project_feature.update_column(:wiki_access_level, ProjectFeature::DISABLED)
          project.reload

          expect do
            result = update_project(project, user, project_feature_attributes: { wiki_access_level: ProjectFeature::ENABLED })
            expect(result).to eq({ status: :success })
          end.not_to change { Geo::RepositoryUpdatedEvent.count }

          expect(project.wiki_enabled?).to be true
        end
      end
    end

    context 'with geo_project_wiki_repository_replication feature flag enabled' do
      before do
        stub_feature_flags(geo_project_wiki_repository_replication: true)
      end

      context 'when on a Geo primary site' do
        before do
          stub_primary_node
        end

        context 'when enabling a wiki' do
          before do
            project.project_feature.update_column(:wiki_access_level, ProjectFeature::DISABLED)
            project.reload
          end

          it 'does not call Geo::RepositoryUpdatedService' do
            expect_next_instance_of(::Geo::RepositoryUpdatedService).never

            result = update_project(project, user, project_feature_attributes: { wiki_access_level: ProjectFeature::ENABLED })

            expect(result).to eq({ status: :success })
            expect(project.wiki_enabled?).to be true
          end

          it 'calls replicator to update Geo' do
            expect_next_instance_of(Geo::ProjectWikiRepositoryReplicator) do |instance|
              expect(instance).to receive(:handle_after_update)
            end

            result = update_project(project, user, project_feature_attributes: { wiki_access_level: ProjectFeature::ENABLED })

            expect(result).to eq({ status: :success })
            expect(project.wiki_enabled?).to be true
          end
        end

        context 'when we update project but not enabling a wiki' do
          context 'when the wiki is disabled' do
            before do
              project.project_feature.update_column(:wiki_access_level, ProjectFeature::DISABLED)
            end

            it 'does not call Geo::RepositoryUpdatedService' do
              expect_next_instance_of(::Geo::RepositoryUpdatedService).never

              result = update_project(project, user, { name: 'test1' })

              expect(result).to eq({ status: :success })
              expect(project.wiki_enabled?).to be false
            end

            it 'does not call replicator to update Geo' do
              expect_next_instance_of(Geo::ProjectWikiRepositoryReplicator).never

              result = update_project(project, user, { name: 'test1' })

              expect(result).to eq({ status: :success })
              expect(project.wiki_enabled?).to be false
            end
          end

          context 'when the wiki was already enabled' do
            before do
              project.project_feature.update_column(:wiki_access_level, ProjectFeature::ENABLED)
            end

            it 'does not call Geo::RepositoryUpdatedService' do
              expect_next_instance_of(::Geo::RepositoryUpdatedService).never

              result = update_project(project, user, { name: 'test1' })

              expect(result).to eq({ status: :success })
              expect(project.wiki_enabled?).to be true
            end

            it 'does not call replicator to update Geo' do
              expect_next_instance_of(Geo::ProjectWikiRepositoryReplicator).never

              result = update_project(project, user, { name: 'test1' })

              expect(result).to eq({ status: :success })
              expect(project.wiki_enabled?).to be true
            end
          end
        end
      end

      context 'when not on a Geo primary site' do
        before do
          stub_secondary_node
        end

        context 'when enabling a wiki' do
          before do
            project.project_feature.update_column(:wiki_access_level, ProjectFeature::DISABLED)
            project.reload
          end

          it 'does not call Geo::RepositoryUpdatedService' do
            expect_next_instance_of(::Geo::RepositoryUpdatedService).never

            result = update_project(project, user, project_feature_attributes: { wiki_access_level: ProjectFeature::ENABLED })

            expect(result).to eq({ status: :success })
            expect(project.wiki_enabled?).to be true
          end

          it 'does not call replicator to update Geo' do
            expect_next_instance_of(Geo::ProjectWikiRepositoryReplicator).never

            result = update_project(project, user, project_feature_attributes: { wiki_access_level: ProjectFeature::ENABLED })

            expect(result).to eq({ status: :success })
            expect(project.wiki_enabled?).to be true
          end
        end
      end
    end
  end

  context 'repository_size_limit assignment as Bytes' do
    let(:admin_user) { create(:user, admin: true) }
    let(:project) { create(:project, repository_size_limit: 0) }

    context 'when param present' do
      let(:opts) { { repository_size_limit: '100' } }

      it 'converts from MB to Bytes' do
        update_project(project, admin_user, opts)

        expect(project.reload.repository_size_limit).to eql(100 * 1024 * 1024)
      end
    end

    context 'when param not present' do
      let(:opts) { { repository_size_limit: '' } }

      it 'assign nil value' do
        update_project(project, admin_user, opts)

        expect(project.reload.repository_size_limit).to be_nil
      end
    end
  end

  context 'when there are merge requests in merge train' do
    before do
      stub_licensed_features(merge_pipelines: true, merge_trains: true)
      project.update!(merge_pipelines_enabled: true)
    end

    let!(:first_merge_request) do
      create(:merge_request, :on_train, target_project: project, source_project: project)
    end

    let!(:second_merge_request) do
      create(:merge_request, :on_train, target_project: project, source_project: project, source_branch: 'feature-1')
    end

    context 'when merge pipelines option is disabled' do
      it 'drops all merge request in the train', :sidekiq_might_not_need_inline do
        expect do
          update_project(project, user, merge_pipelines_enabled: false)
        end.to change { MergeTrains::Car.count }.from(2).to(0)
      end
    end

    context 'when merge pipelines option stays enabled' do
      it 'does not drop all merge request in the train' do
        expect do
          update_project(project, user, merge_pipelines_enabled: true)
        end.not_to change { MergeTrains::Car.count }
      end
    end
  end

  context 'triggering suggested reviewer project registrations' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }

    let(:opts) { { project_setting_attributes: { suggested_reviewers_enabled: '1' } } }

    before do
      group.add_maintainer(user)
      project.add_maintainer(user)
    end

    shared_examples 'calling registration worker' do
      it 'calls perform_async' do
        expect(::Projects::RegisterSuggestedReviewersProjectWorker)
          .to receive(:perform_async)
                .with(project.id, user.id)

        update_project(project, user, opts)
      end
    end

    shared_examples 'not calling registration worker' do
      it 'does not call perform_async' do
        expect(::Projects::RegisterSuggestedReviewersProjectWorker).not_to receive(:perform_async)

        update_project(project, user, opts)
      end
    end

    context 'when available' do
      before do
        allow(project).to receive(:suggested_reviewers_available?).and_return(true)
      end

      context 'when enabled' do
        before do
          project.project_setting.update! suggested_reviewers_enabled: true
        end

        it_behaves_like 'not calling registration worker'
      end

      context 'when not enabled' do
        before do
          project.project_setting.update! suggested_reviewers_enabled: false
        end

        context 'when not allowed to create access token' do
          before do
            group.namespace_settings.update! resource_access_token_creation_allowed: false
          end

          it_behaves_like 'not calling registration worker'
        end

        context 'when allowed to create access token', :saas do
          before do
            group.namespace_settings.update! resource_access_token_creation_allowed: true
          end

          it_behaves_like 'calling registration worker'

          it 'sets the setting' do
            expect { update_project(project, user, opts) }
              .to change { project.reload.suggested_reviewers_enabled }.from(false).to(true)
          end

          context 'when form param is set to false' do
            let(:opts) { { project_setting_attributes: { suggested_reviewers_enabled: '0' } } }

            it_behaves_like 'not calling registration worker'
          end
        end
      end
    end

    context 'when not available' do
      before do
        allow(project).to receive(:suggested_reviewers_available?).and_return(false)
      end

      context 'when enabled' do
        before do
          project.project_setting.update! suggested_reviewers_enabled: true
        end

        it_behaves_like 'not calling registration worker'
      end

      context 'when not enabled' do
        before do
          project.project_setting.update! suggested_reviewers_enabled: false
        end

        it_behaves_like 'not calling registration worker'

        it 'does not set the setting' do
          expect { update_project(project, user, opts) }.not_to change { project.reload.suggested_reviewers_enabled }
        end
      end
    end
  end

  context 'when triggering suggested reviewers project deregistrations' do
    let_it_be_with_reload(:project) { create(:project) }

    let(:opts) { { project_setting_attributes: { suggested_reviewers_enabled: '0' } } }

    before_all do
      project.add_maintainer(user)
    end

    shared_examples 'calling deregistration worker' do
      it 'calls perform_async' do
        expect(::Projects::DeregisterSuggestedReviewersProjectWorker)
          .to receive(:perform_async).with(project.id, user.id)

        update_project(project, user, opts)
      end

      it 'changes the setting' do
        expect { update_project(project, user, opts) }
          .to change { project.reload.suggested_reviewers_enabled }.from(true).to(false)
      end
    end

    shared_examples 'not calling deregistration worker' do
      it 'does not call perform_async' do
        expect(::Projects::DeregisterSuggestedReviewersProjectWorker).not_to receive(:perform_async)

        update_project(project, user, opts)
      end

      it 'does not change the setting' do
        expect { update_project(project, user, opts) }.not_to change { project.reload.suggested_reviewers_enabled }
      end
    end

    context 'when available' do
      before do
        allow(project).to receive(:suggested_reviewers_available?).and_return(true)
      end

      context 'when not enabled' do
        before do
          project.project_setting.update!(suggested_reviewers_enabled: false)
        end

        it_behaves_like 'not calling deregistration worker'
      end

      context 'when enabled', :saas do
        before do
          project.project_setting.update!(suggested_reviewers_enabled: true)
        end

        it_behaves_like 'calling deregistration worker'

        context 'when form param is set to true' do
          let(:opts) { { project_setting_attributes: { suggested_reviewers_enabled: '1' } } }

          it_behaves_like 'not calling deregistration worker'
        end
      end
    end

    context 'when not available' do
      before do
        allow(project).to receive(:suggested_reviewers_available?).and_return(false)
      end

      context 'when not enabled' do
        before do
          project.project_setting.update!(suggested_reviewers_enabled: false)
        end

        it_behaves_like 'not calling deregistration worker'
      end

      context 'when enabled' do
        before do
          project.project_setting.update!(suggested_reviewers_enabled: true)
        end

        it_behaves_like 'not calling deregistration worker'
      end
    end
  end

  context 'custom compliance frameworks' do
    let(:group) { create(:group) }
    let(:project) { create(:project, group: group) }
    let(:framework) { create(:compliance_framework, namespace: group) }
    let(:opts) { { compliance_framework_setting_attributes: { framework: framework.id } } }

    context 'when current_user has :admin_compliance_framework ability' do
      before do
        stub_licensed_features(compliance_framework: true)
        group.add_owner(user)
        project.add_owner(user)
      end

      it 'updates the framework' do
        expect { update_project(project, user, opts) }.to change {
          project
            .reload
            .compliance_management_framework
        }.from(nil).to(framework)
      end

      it 'unassigns a framework from a project' do
        project.compliance_management_framework = framework

        expect { update_project(project, user, { compliance_framework_setting_attributes: { framework: nil } }) }.to change {
          project
            .reload
            .compliance_management_framework
        }.from(framework).to(nil)
      end
    end

    context 'when current_user does not have :admin_compliance_framework ability' do
      before do
        stub_licensed_features(compliance_framework: false)
      end

      it 'does not set a framework' do
        update_project(project, user, opts)

        expect(project.reload.compliance_management_framework).not_to be_present
      end
    end
  end

  it 'returns an error result when record cannot be updated' do
    admin = create(:admin)

    result = update_project(project, admin, { name: 'foo&bar' })

    expect(result).to eq({ status: :error, message: "Name can contain only letters, digits, emojis, '_', '.', '+', dashes, or spaces. It must start with a letter, digit, emoji, or '_'." })
  end

  it 'calls remove_import_data if mirror was disabled in previous change' do
    update_project(project, user, { mirror: false })

    expect(project.import_data).to be_nil
    expect(project).not_to be_mirror
  end

  context 'updating analytics_dashboards_pointer_attributes.target_project_id param' do
    let_it_be(:user) { create :user }
    let_it_be(:group) { create(:group) { |g| g.add_owner(user) } }

    let(:project) { create :project, namespace: group }
    let(:sibling_project) { create :project, namespace: group }

    let(:attrs) { { analytics_dashboards_pointer_attributes: { target_project_id: sibling_project.id } } }

    it 'updates the Analytics Dashboards pointer project' do
      update_project(project, user, attrs)

      expect(project.analytics_dashboards_pointer.target_project).to eq(sibling_project)
    end

    context 'when pointer project is empty' do
      let(:existing_pointer) do
        create(:analytics_dashboards_pointer, project: project, namespace: nil, target_project: sibling_project)
      end

      let(:attrs) { { analytics_dashboards_pointer_attributes: { id: existing_pointer.id, target_project_id: '' } } }

      it 'removes pointer project' do
        update_project(project, user, attrs)

        expect(project.reload.analytics_dashboards_pointer).to eq(nil)
      end
    end
  end

  def update_project(project, user, opts)
    Projects::UpdateService.new(project, user, opts).execute
  end
end
