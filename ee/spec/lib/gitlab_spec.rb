# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab do
  describe '.com?' do
    context 'when simulating SaaS' do
      before do
        stub_const('Gitlab::GITLAB_SIMULATE_SAAS', '1')
      end

      it 'is false in tests' do
        expect(described_class.com?).to eq false
      end

      it 'is true in development' do
        stub_rails_env('development')

        expect(described_class.com?).to eq true
      end

      context 'in a production environment' do
        before do
          stub_rails_env('production')
        end

        context 'without a license' do
          it 'is false' do
            expect(described_class.com?).to eq false
          end
        end

        context 'when a license is present' do
          let(:license) { instance_double(::License) }

          before do
            allow(::License).to receive(:current).and_return(license)
          end

          context 'when issued to a GitLab team member' do
            it 'is true' do
              expect(license).to receive(:issued_to_gitlab_team_member?).and_return(true)
              expect(described_class.com?).to eq true
            end
          end

          context 'when not issued to a GitLab team member' do
            it 'is false' do
              expect(license).to receive(:issued_to_gitlab_team_member?).and_return(false)
              expect(described_class.com?).to eq false
            end
          end
        end
      end
    end
  end
end
