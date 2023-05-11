# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Metrics rendering', :js, :kubeclient, :use_clean_rails_memory_store_caching, :sidekiq_inline,
feature_category: :team_planning do
  include PrometheusHelpers
  include KubernetesHelpers
  include MetricsDashboardUrlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :with_prometheus_integration) }

  let(:issue) { create(:issue, project: project, description: description) }

  before do
    stub_feature_flags(remove_monitor_metrics: false)

    clear_host_from_memoized_variables
    stub_gitlab_domain

    stub_licensed_features(prometheus_alerts: true)

    project.add_maintainer(user)
    sign_in(user)

    import_common_metrics
    stub_any_prometheus_request_with_response

    allow(Prometheus::ProxyService).to receive(:new).and_call_original
  end

  after do
    clear_host_from_memoized_variables
  end

  # While migrating alerting to CE.
  # this context block can be moved after removing the 'unlicensed' context to inside the
  # 'internal metrics embeds' block in spec/features/markdown/metrics_spec.rb
  # Add `:alert_regex` to clear_host_from_memoized_variables
  context 'for GitLab-managed alerting rules' do
    let(:metric) { PrometheusMetric.last }
    let!(:alert) { create(:prometheus_alert, project: project, prometheus_metric: metric) }
    let(:description) { "# Summary \n[](#{metrics_url})" }
    let(:metrics_url) do
      urls.metrics_dashboard_project_prometheus_alert_url(
        project,
        metric.id,
        environment_id: alert.environment_id,
        embedded: true
      )
    end

    it 'shows embedded metrics' do
      visit project_issue_path(project, issue)

      expect(page).to have_css('div.prometheus-graph')
      expect(page).to have_text(metric.title)
      expect(page).to have_text(metric.y_label)
      expect(page).not_to have_text(metrics_url)

      expect(Prometheus::ProxyService)
        .to have_received(:new)
        .with(alert.environment, 'GET', 'query_range', hash_including('start', 'end', 'step'))
        .at_least(:once)
    end

    context 'with remove_monitor_metrics flag enabled' do
      before do
        stub_feature_flags(remove_monitor_metrics: true)
      end

      it 'does not show embedded metrics' do
        visit project_issue_path(project, issue)

        expect(page).not_to have_css('div.prometheus-graph')
        expect(page).not_to have_text(metric.title)
        expect(page).not_to have_text(metric.y_label)
      end
    end

    # Delete when moving to CE
    context 'unlicensed' do
      before do
        stub_licensed_features(prometheus_alerts: false)
      end

      it 'shows no embedded metrics' do
        visit project_issue_path(project, issue)

        expect(page).to have_no_css('div.prometheus-graph')
      end
    end
  end

  context 'for GitLab embedded cluster health metrics' do
    before do
      create(:clusters_integrations_prometheus, cluster: cluster)
      stub_kubeclient_discover(cluster.platform.api_url)
      stub_prometheus_request(/prometheus-prometheus-server/, body: prometheus_values_body)
      stub_prometheus_request(%r{prometheus/api/v1}, body: prometheus_values_body)
    end

    let_it_be(:cluster) { create(:cluster, :provided_by_gcp, :project, projects: [project], user: user) }

    let(:params) { [project.namespace.path, project.path, cluster.id] }
    let(:query_params) { { group: 'Cluster Health', title: 'CPU Usage', y_label: 'CPU (cores)' } }
    let(:metrics_url) { urls.metrics_namespace_project_cluster_url(*params, **query_params) }
    let(:description) { "# Summary \n[](#{metrics_url})" }

    it 'shows embedded metrics' do
      visit project_issue_path(project, issue)

      expect(page).to have_css('div.metrics-embed')
      expect(page).to have_text(query_params[:title])
      expect(page).to have_text(query_params[:y_label])
      expect(page).not_to have_text(metrics_url)

      expect(Prometheus::ProxyService)
        .to have_received(:new)
        .with(cluster, 'GET', 'query_range', hash_including('start', 'end', 'step'))
        .at_least(:once)
    end

    context 'when metrics dashboard feature is unavailable' do
      before do
        stub_feature_flags(remove_monitor_metrics: true)
      end

      it 'shows no embedded metrics' do
        visit project_issue_path(project, issue)

        expect(page).to have_no_css('div.prometheus-graph')
      end
    end
  end

  def import_common_metrics
    ::Gitlab::DatabaseImporters::CommonMetrics::Importer.new.execute
  end
end
