# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DependencyEntity do
  describe '#as_json' do
    subject { described_class.represent(dependency, request: request).as_json }

    let_it_be(:user) { create(:user) }

    let(:project) { create(:project, :repository, :private) }
    let(:request) { double('request') }
    let(:dependency) { build(:dependency, :with_vulnerabilities, :with_licenses, :indirect) }

    before do
      allow(request).to receive(:project).and_return(project)
      allow(request).to receive(:user).and_return(user)
    end

    context 'when all required features available' do
      before do
        stub_licensed_features(security_dashboard: true, license_scanning: true)
        allow(request).to receive(:project).and_return(project)
        allow(request).to receive(:user).and_return(user)
      end

      context 'with developer' do
        before do
          project.add_developer(user)
        end

        it 'includes license info and vulnerabilities' do
          is_expected.to eq(dependency.except(:package_manager, :iid))
        end

        it 'does not include component_id' do
          expect(subject.keys).not_to include(:component_id)
        end
      end

      context 'with reporter' do
        before do
          project.add_reporter(user)
        end

        it 'includes license info and not vulnerabilities' do
          is_expected.to eq(dependency.except(:vulnerabilities, :package_manager, :iid))
        end
      end

      context 'with project' do
        let(:dependency) { build(:dependency, project: project) }

        before do
          allow(request).to receive(:project).and_return(nil)
        end

        it 'includes project name and full_path' do
          result = subject

          expect(result.dig(:project, :full_path)).to eq(project.full_path)
          expect(result.dig(:project, :name)).to eq(project.name)
        end

        it 'includes component_id' do
          expect(subject.keys).to include(:component_id)
        end
      end
    end

    context 'when all required features are unavailable' do
      before do
        project.add_developer(user)
      end

      it 'does not include licenses and vulnerabilities' do
        is_expected.to eq(dependency.except(:vulnerabilities, :licenses, :package_manager, :iid))
      end
    end

    context 'when there is no dependency path attributes' do
      let(:dependency) { build(:dependency, :with_vulnerabilities, :with_licenses) }

      it 'correctly represent location' do
        location = subject[:location]

        expect(location[:ancestors]).to be_nil
        expect(location[:top_level]).to be_nil
        expect(location[:path]).to eq('package_file.lock')
      end
    end
  end
end
