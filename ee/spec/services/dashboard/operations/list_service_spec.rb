# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dashboard::Operations::ListService, feature_category: :continuous_delivery do
  let(:subject) { described_class.new(user).execute }
  let(:dashboard_project) { subject.first }

  let!(:project) { create(:project, :repository) }
  let!(:user) { create(:user) }

  describe '#execute' do
    let(:projects_service) { double(Dashboard::Projects::ListService) }

    before do
      allow(Dashboard::Projects::ListService)
        .to receive(:new).with(user, feature: :operations_dashboard).and_return(projects_service)
    end

    shared_examples 'no projects' do
      it 'returns an empty list' do
        expect(subject).to be_empty
      end

      it 'ensures only a single query' do
        queries = ActiveRecord::QueryRecorder.new { subject }.count

        expect(queries).to eq(1)
      end
    end

    shared_examples 'no deployment information' do
      it 'has no information' do
        expect(dashboard_project.last_deployment).to be_nil
        expect(dashboard_project.alert_count).to eq(0)
        expect(dashboard_project.last_alert).to be_nil
      end
    end

    shared_examples 'avoiding N+1 queries' do
      it 'ensures a fixed amount of queries' do
        queries = ActiveRecord::QueryRecorder.new { subject }.count

        expect(queries).to eq(7)
      end
    end

    context 'with added projects' do
      let(:production) { create(:environment, project: project, name: 'production') }
      let(:staging) { create(:environment, project: project, name: 'staging') }

      let(:production_deployment) do
        create(:deployment, :success, project: project, environment: production, ref: 'master')
      end

      let(:staging_deployment) do
        create(:deployment, :success, project: project, environment: staging, ref: 'wip')
      end

      before do
        user.ops_dashboard_projects << project

        allow(projects_service)
          .to receive(:execute)
          .with([project], include_unavailable: true)
          .and_return([project])
      end

      it 'returns a list of projects' do
        expect(subject.size).to eq(1)
      end

      it 'has some project information' do
        expect(dashboard_project.project).to eq(project)
      end

      it_behaves_like 'no deployment information'

      context 'with `production` deployment' do
        before do
          staging_deployment
          production_deployment
        end

        it 'provides information about the `production` deployment' do
          last_deployment = dashboard_project.last_deployment

          expect(last_deployment.ref).to eq(production_deployment.ref)
        end

        context 'with alerts' do
          let(:alert_prd1) { create(:prometheus_alert, project: project, environment: production) }
          let(:alert_prd2) { create(:prometheus_alert, project: project, environment: production) }
          let(:alert_stg) { create(:prometheus_alert, project: project, environment: staging) }

          let!(:alert_events) do
            [
              create(:alert_management_alert, prometheus_alert: alert_prd1, environment: production, project: project),
              create(:alert_management_alert, prometheus_alert: alert_prd2, environment: production, project: project),
              last_firing_event,
              create(:alert_management_alert, prometheus_alert: alert_stg, environment: staging, project: project),
              create(:alert_management_alert, :resolved, prometheus_alert: alert_prd2, environment: production, project: project)
            ]
          end

          let(:last_firing_event) { create(:alert_management_alert, prometheus_alert: alert_prd1, environment: production, project: project) }

          it_behaves_like 'avoiding N+1 queries'

          it 'provides information about alerts' do
            expect(dashboard_project.alert_count).to eq(3)
            expect(dashboard_project.last_alert).to eq(last_firing_event.prometheus_alert)
          end

          context 'with more projects' do
            before do
              project2 = create(:project)
              production2 = create(:environment, name: 'production', project: project2)
              alert2_prd = create(:prometheus_alert, project: project2, environment: production2)
              create(:alert_management_alert, prometheus_alert: alert2_prd, environment: production2, project: project2)

              user.ops_dashboard_projects << project2

              allow(projects_service)
                .to receive(:execute)
                .with([project, project2], include_unavailable: true)
                .and_return([project, project2])
            end

            it_behaves_like 'avoiding N+1 queries'
          end
        end
      end

      context 'without any `production` deployments' do
        before do
          staging_deployment
        end

        it_behaves_like 'no deployment information'
      end

      context 'without deployments' do
        it_behaves_like 'no deployment information'
      end
    end

    context 'without added projects' do
      before do
        allow(projects_service)
          .to receive(:execute)
          .with([], include_unavailable: true)
          .and_return([])
      end

      it_behaves_like 'no projects'
    end
  end
end
