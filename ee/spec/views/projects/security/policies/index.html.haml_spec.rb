# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "projects/security/policies/index", type: :view do
  let(:user) { project.first_owner }
  let(:project) { create(:project) }

  before do
    sign_in(user)
    render template: 'projects/security/policies/index', locals: { project: project }
  end

  it 'renders Vue app root' do
    expect(rendered).to have_selector('#js-security-policies-list')
  end

  it "passes project's full path" do
    expect(rendered).to include project.path_with_namespace
  end

  it 'passes documentation URL' do
    expect(rendered).to include '/help/user/application_security/policies/index.md'
  end
end
