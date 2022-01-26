# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::ZentaoMenu do
  let(:project) { create(:project, has_external_issue_tracker: true) }
  let(:user) { project.first_owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }
  let(:zentao_integration) { create(:zentao_integration, project: project) }

  subject { described_class.new(context) }

  describe 'when feature is not licensed' do
    before do
      stub_licensed_features(zentao_issues_integration: false)
    end

    it_behaves_like 'ZenTao menu with CE version'
  end

  describe 'when feature is licensed' do
    before do
      stub_licensed_features(zentao_issues_integration: true)
    end

    context 'when issues integration is disabled' do
      before do
        zentao_integration.update!(active: false)
      end

      it 'returns false' do
        expect(subject.render?).to eq false
      end
    end

    context 'when issues integration is enabled' do
      before do
        zentao_integration.update!(active: true)
      end

      it 'returns true' do
        expect(subject.render?).to eq true
      end

      it 'renders menu link' do
        expect(subject.link).to include('/-/integrations/zentao/issues')
      end

      it 'contains issue list and open ZenTao menu items' do
        expect(subject.renderable_items.map(&:item_id)).to match_array [:issue_list, :open_zentao]
      end
    end
  end
end
