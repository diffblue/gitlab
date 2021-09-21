# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::Sites::FindOrCreateService do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, creator: user) }
  let(:url) { generate(:url) }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  describe '#execute!' do
    subject { described_class.new(project, user).execute!(url: url) }

    context 'when a user does not have access to the project' do
      it 'raises an exception' do
        expect { subject }.to raise_error(described_class::PermissionsError) do |err|
          expect(err.message).to include('Insufficient permissions')
        end
      end
    end

    context 'when the user can run a dast scan' do
      before do
        project.add_developer(user)
      end

      it 'returns a dast_site' do
        expect(subject).to be_a(DastSite)
      end

      it 'creates a dast_site' do
        expect { subject }.to change(DastSite, :count).by(1)
      end

      context 'when the dast_site already exists' do
        before do
          create(:dast_site, project: project, url: url)
        end

        it 'returns the existing dast_site' do
          expect(subject).to be_a(DastSite)
        end

        it 'does not create a new dast_site' do
          expect { subject }.not_to change(DastSite, :count)
        end
      end

      context 'when the record is invalid' do
        let(:url) { 'i-am-not-a-url' }

        it 'raises an exception' do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid) do |err|
            expect(err.record.errors.full_messages).to include('Url is blocked: Only allowed schemes are http, https')
          end
        end
      end

      context 'when on demand scan licensed feature is not available' do
        it 'raises an exception' do
          stub_licensed_features(security_on_demand_scans: false)

          expect { subject }.to raise_error(described_class::PermissionsError) do |err|
            expect(err.message).to include('Insufficient permissions')
          end
        end
      end
    end
  end
end
