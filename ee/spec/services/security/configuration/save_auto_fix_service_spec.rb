# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Configuration::SaveAutoFixService, feature_category: :software_composition_analysis do
  describe '#execute' do
    let_it_be_with_reload(:project) { create(:project) }

    let(:service) { described_class.new(project, feature) }

    subject(:response) { service.execute(enabled: false) }

    context 'with supported scanner type' do
      let(:feature) { 'dependency_scanning' }

      it 'returns success status' do
        expect(response).to be_success
        expect(response.payload).to eq({ container_scanning: true, dependency_scanning: false })
      end

      it 'changes setting' do
        response

        expect(project.security_setting.auto_fix_dependency_scanning).to be_falsey
      end
    end

    context 'with all scanners' do
      let(:feature) { 'all' }

      it 'returns success status' do
        expect(response).to be_success
      end

      it 'changes setting' do
        response

        expect(project.security_setting.auto_fix_dependency_scanning).to be_falsey
        expect(project.security_setting.auto_fix_container_scanning).to be_falsey
      end
    end

    context 'with not supported scanner type' do
      let(:feature) { :dep_scan }

      it 'does not change setting' do
        expect(response).to be_error
        expect(response.message).to eq('Auto fix is not available for dep_scan feature')
      end
    end
  end
end
