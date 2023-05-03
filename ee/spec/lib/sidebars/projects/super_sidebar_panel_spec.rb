# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::SuperSidebarPanel, feature_category: :navigation do
  let_it_be(:project) { create(:project, :repository) }

  let(:user) { project.first_owner }
  let(:context) do
    Sidebars::Projects::Context.new(
      current_user: user,
      container: project,
      current_ref: project.repository.root_ref,
      is_super_sidebar: true,
      # Turn features on that impact the list of items rendered
      can_view_pipeline_editor: true,
      learn_gitlab_enabled: true,
      show_discover_project_security: true,
      # Turn features off that do not add/remove items
      show_cluster_hint: false,
      show_promotions: false
    )
  end

  subject { described_class.new(context) }

  # We want to enable _all_ possible menu items for these specs
  before do
    # Give the user access to everything and enable every feature
    allow(Ability).to receive(:allowed?).and_return(true)
    allow(project).to receive(:licensed_feature_available?).and_return true
    # Needed to show Container Registry items
    allow(::Gitlab.config.registry).to receive(:enabled).and_return(true)
    # This feature flag removes the monitor metrics menu item, so turn it off
    stub_feature_flags(remove_monitor_metrics: false)
    # Iterations are only available in non-personal projects
    allow(project).to receive(:personal?).and_return(false)
  end

  it_behaves_like 'a panel with uniquely identifiable menu items'
  it_behaves_like 'a panel with all menu_items categorized'
  it_behaves_like 'a panel without placeholders'
end
