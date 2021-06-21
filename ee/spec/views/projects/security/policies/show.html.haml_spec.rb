# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "projects/security/policies/show", type: :view do
  let(:user) { project.owner }
  let(:project) { create(:project) }

  before do
    stub_feature_flags(security_orchestration_policies_configuration: true)
    sign_in(user)
    render template: 'projects/security/policies/show', locals: { project: project }
  end

  it 'renders Vue app root' do
    expect(rendered).to have_selector('#js-security-policies-list')
  end

  it "passes project's full path" do
    expect(rendered).to include project.path_with_namespace
  end

  it 'passes documentation URL' do
    expect(rendered).to include '/help/user/project/clusters/protect/container_network_security/quick_start_guide'
  end
end
