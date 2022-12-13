# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Vulnerabilities::Parser, feature_category: :vulnerability_management do
  describe '.fabricate' do
    let(:params) do
      {
        target_branch: 'master'
      }
    end

    subject { described_class.fabricate(params) }

    context 'with standard categories' do
      let(:categories) do
        %w(
          sast
          dast
          dependency_scanning
        )
      end

      it 'returns a Standard Vulnerability' do
        categories.each do |category|
          params[:category] = category
          expect(subject).to be_a(Gitlab::Vulnerabilities::StandardVulnerability)
          expect(subject.target_branch).to eq('master')
        end
      end
    end

    context 'with container scanning as category' do
      it 'returns a Scanning Vulnerability' do
        params[:category] = 'container_scanning'

        expect(subject).to be_a(Gitlab::Vulnerabilities::ContainerScanningVulnerability)
        expect(subject.target_branch).to eq('master')
      end
    end

    context 'with cluster image scanning as category' do
      it 'returns a Scanning Vulnerability' do
        params[:category] = 'cluster_image_scanning'

        expect(subject).to be_a(Gitlab::Vulnerabilities::ContainerScanningVulnerability)
        expect(subject.target_branch).to eq('master')
      end
    end

    context 'with an invalid category' do
      it 'raises an exception' do
        params[:category] = 'foo'
        expect { subject }.to raise_error(Gitlab::Vulnerabilities::InvalidCategoryError)
      end
    end
  end
end
