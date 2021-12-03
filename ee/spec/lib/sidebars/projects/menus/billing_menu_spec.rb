# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::BillingMenu do
  it_behaves_like 'billing menu items' do
    let(:context) do
      container = instance_double(Project, namespace: group)
      Sidebars::Projects::Context.new(current_user: user, container: container)
    end
  end
end
