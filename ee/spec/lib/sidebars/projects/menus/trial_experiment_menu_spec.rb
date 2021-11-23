# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::TrialExperimentMenu, :saas do
  it_behaves_like 'trial experiment menu items' do
    let(:context) do
      container = instance_double(Project, namespace: group)
      Sidebars::Projects::Context.new(current_user: user, container: container)
    end
  end
end
