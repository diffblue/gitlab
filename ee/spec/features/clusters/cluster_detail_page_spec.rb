# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Clusterable > Show page', feature_category: :deployment_management do
  include KubernetesHelpers

  let(:current_user) { create(:user) }
  let(:cluster_ingress_help_text_selector) { '.js-ingress-domain-help-text' }
  let(:hide_modifier_selector) { '.hide' }

  before do
    stub_licensed_features(cluster_deployments: true)

    sign_in(current_user)
  end

  context 'when clusterable is a project' do
    let(:clusterable) { create(:project) }
    let(:cluster_path) { project_cluster_path(clusterable, cluster) }
    let(:cluster) { create(:cluster, :provided_by_gcp, :project, projects: [clusterable]) }

    before do
      clusterable.add_maintainer(current_user)
    end

    it 'does not show the environments tab' do
      visit cluster_path

      expect(page).not_to have_selector('[data-testid="cluster-environments-tab"]')
    end
  end

  context 'when clusterable is a group' do
    let(:clusterable) { create(:group) }
    let(:cluster_path) { group_cluster_path(clusterable, cluster) }
    let(:cluster) { create(:cluster, :provided_by_gcp, :group, groups: [clusterable]) }

    before do
      clusterable.add_maintainer(current_user)
    end

    it 'shows the environments tab' do
      visit cluster_path

      expect(page).to have_selector('[data-testid="cluster-environments-tab"]', text: 'Environments')
    end
  end

  context 'when clusterable is an instance' do
    let(:current_user) { create(:admin) }
    let(:cluster_path) { admin_cluster_path(cluster) }
    let(:cluster) { create(:cluster, :provided_by_gcp, :instance) }

    before do
      gitlab_enable_admin_mode_sign_in(current_user)
    end

    it 'shows the environments tab' do
      visit cluster_path

      expect(page).to have_selector('[data-testid="cluster-environments-tab"]', text: 'Environments')
    end
  end
end
