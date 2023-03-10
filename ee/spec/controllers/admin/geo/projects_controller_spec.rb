# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::Geo::ProjectsController, :geo, feature_category: :geo_replication do
  include EE::GeoHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:geo_primary) { create(:geo_node, :primary) }

  let(:synced_registry) { create(:geo_project_registry, :synced) }

  before do
    sign_in(admin)
  end

  shared_examples 'license required' do
    context 'without a valid license' do
      it 'redirects to 403 page' do
        expect(subject).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe '#index' do
    subject { get :index }

    it_behaves_like 'license required'

    context 'with a valid license' do
      render_views

      before do
        stub_licensed_features(geo: true)
        stub_current_geo_node(create(:geo_node))
      end

      it 'displays a different read-only message based on skip_readonly_message' do
        expect(subject.body).to match('You may be able to make a limited amount of changes or perform a limited amount of actions on this page')
        expect(subject.body).to include(geo_primary.url)
      end

      context 'warns about viewing replication data' do
        let(:expected_warning) { 'Viewing projects and designs data from a primary site is not possible when using a unified URL. Visit the secondary site directly.' }

        context 'on a Geo primary' do
          before do
            stub_primary_node
          end

          it 'renders the warning on a primary' do
            expect(subject.body).to match(expected_warning)
            expect(subject.body).to include(
              help_page_url('administration/geo/index', anchor: 'view-replication-data-on-the-primary-site')
            )
          end
        end

        context 'on a Geo secondary' do
          before do
            stub_secondary_node
          end

          it 'does not render the warning on a secondary' do
            expect(subject.body).not_to match(expected_warning)
            expect(subject.body).not_to include(
              help_page_url('administration/geo/index', anchor: 'view-replication-data-on-the-primary-site')
            )
          end
        end
      end

      context 'without sync_status specified' do
        it 'renders all template when no extra get params is specified' do
          expect(subject).to have_gitlab_http_status(:ok)
          expect(subject).to render_template(:index)
          expect(subject).to render_template(partial: 'admin/geo/projects/_all')
        end
      end

      context 'with sync_status=pending' do
        subject { get :index, params: { sync_status: 'pending' } }

        it 'renders pending template' do
          expect(subject).to have_gitlab_http_status(:ok)
          expect(subject).to render_template(:index)
          expect(subject).to render_template(partial: 'admin/geo/projects/_pending')
        end
      end

      context 'with sync_status=failed' do
        subject { get :index, params: { sync_status: 'failed' } }

        it 'renders failed template' do
          expect(subject).to have_gitlab_http_status(:ok)
          expect(subject).to render_template(:index)
          expect(subject).to render_template(partial: 'admin/geo/projects/_failed')
        end
      end

      context 'with sync_status=synced' do
        subject { get :index, params: { sync_status: 'synced' } }

        it 'renders synced template' do
          expect(subject).to have_gitlab_http_status(:ok)
          expect(subject).to render_template(:index)
          expect(subject).to render_template(partial: 'admin/geo/projects/_synced')
        end
      end
    end
  end

  describe '#destroy' do
    subject { delete :destroy, params: { id: synced_registry } }

    it_behaves_like 'license required'

    context 'with a valid license' do
      before do
        stub_licensed_features(geo: true)
      end

      context 'with an orphaned registry' do
        it 'removes the registry' do
          synced_registry.update_column(:project_id, -1)

          expect(subject).to redirect_to(admin_geo_projects_path)
          expect(flash[:toast]).to include('was successfully removed')
          expect { Geo::ProjectRegistry.find(synced_registry.id) }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'with a regular registry' do
        it 'removes the registry' do
          expect(subject).to redirect_to(admin_geo_projects_path)
          expect(flash[:alert]).to include('Could not remove tracking entry')
          expect { Geo::ProjectRegistry.find(synced_registry.id) }.not_to raise_error
        end
      end
    end
  end

  describe '#reverify' do
    subject { post :reverify, params: { id: synced_registry } }

    it_behaves_like 'license required'

    context 'with a valid license' do
      before do
        stub_licensed_features(geo: true)
      end

      it 'flags registry for reverify' do
        expect(subject).to redirect_to(admin_geo_projects_path)
        expect(flash[:toast]).to include('is scheduled for re-verify')
        expect(synced_registry.reload.pending_verification?).to be_truthy
      end
    end
  end

  describe '#resync' do
    subject { post :resync, params: { id: synced_registry } }

    it_behaves_like 'license required'

    context 'with a valid license' do
      before do
        stub_licensed_features(geo: true)
      end

      it 'flags registry for resync' do
        expect(subject).to redirect_to(admin_geo_projects_path)
        expect(flash[:toast]).to include('is scheduled for re-sync')
        expect(synced_registry.reload.resync_repository?).to be_truthy
      end
    end
  end

  describe '#reverify_all' do
    subject { post :reverify_all }

    it_behaves_like 'license required'

    context 'with a valid license' do
      before do
        stub_licensed_features(geo: true)
      end

      it 'schedules a batch job' do
        Sidekiq::Testing.fake! do
          expect { subject }.to change { Geo::Batch::ProjectRegistrySchedulerWorker.jobs.size }.by(1)
          expect(Geo::Batch::ProjectRegistrySchedulerWorker.jobs.last['args']).to include('reverify_repositories')
        end
      end

      it 'redirects back and display confirmation' do
        Sidekiq::Testing.inline! do
          expect(subject).to redirect_to(admin_geo_projects_path)
          expect(flash[:toast]).to include('All projects are being scheduled for reverify')
        end
      end
    end
  end

  describe '#resync_all' do
    subject { post :resync_all }

    it_behaves_like 'license required'

    context 'with a valid license' do
      before do
        stub_licensed_features(geo: true)
      end

      it 'schedules a batch job' do
        Sidekiq::Testing.fake! do
          expect { subject }.to change { Geo::Batch::ProjectRegistrySchedulerWorker.jobs.size }.by(1)
          expect(Geo::Batch::ProjectRegistrySchedulerWorker.jobs.last['args']).to include('resync_repositories')
        end
      end

      it 'redirects back and display confirmation' do
        expect(subject).to redirect_to(admin_geo_projects_path)
        expect(flash[:toast]).to include('All projects are being scheduled for resync')
      end
    end
  end

  describe '#force_redownload' do
    subject { post :force_redownload, params: { id: synced_registry } }

    it_behaves_like 'license required'

    context 'with a valid license' do
      before do
        stub_licensed_features(geo: true)
      end

      it 'flags registry for re-download' do
        expect(subject).to redirect_to(admin_geo_projects_path)
        expect(flash[:toast]).to include('is scheduled for forced re-download')
        expect(synced_registry.reload.should_be_redownloaded?('repository')).to be_truthy
      end
    end
  end
end
