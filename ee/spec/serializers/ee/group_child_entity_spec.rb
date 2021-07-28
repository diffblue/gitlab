# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupChildEntity do
  include ExternalAuthorizationServiceHelpers
  include Gitlab::Routing.url_helpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :with_sox_compliance_framework) }
  let_it_be(:project_without_compliance_framework) { create(:project) }
  let_it_be(:group) { create(:group) }

  let(:request) { double('request') }
  let(:entity) { described_class.new(object, request: request) }

  subject(:json) { entity.as_json }

  before do
    allow(request).to receive(:current_user).and_return(user)
    stub_commonmark_sourcepos_disabled
  end

  describe 'with compliance framework' do
    shared_examples 'does not have the compliance framework' do
      it do
        expect(json[:compliance_management_framework]).to be_nil
      end
    end

    context 'disabled' do
      before do
        stub_licensed_features(compliance_framework: false)
      end

      context 'for a project' do
        let(:object) { project }

        it_behaves_like 'does not have the compliance framework'
      end

      context 'for a group' do
        let(:object) { group }

        it_behaves_like 'does not have the compliance framework'
      end
    end

    describe 'enabled' do
      before do
        stub_licensed_features(compliance_framework: true)
      end

      context 'for a project' do
        let(:object) { project }

        it 'has the compliance framework' do
          expect(json[:compliance_management_framework]['name']).to eq('SOX')
        end
      end

      context 'for a project without a compliance framework' do
        let(:object) { project_without_compliance_framework }

        it_behaves_like 'does not have the compliance framework'
      end

      context 'for a group' do
        let(:object) { group }

        it_behaves_like 'does not have the compliance framework'
      end
    end
  end
end
