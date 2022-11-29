# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::ScannerPresenter, :threat_insights, feature_category: :vulnerability_management do
  using RSpec::Parameterized::TableSyntax

  let(:presenter) { described_class.new(scanner) }
  let(:scanner) { build_stubbed(:vulnerabilities_scanner) }

  describe '#to_global_id' do
    subject { presenter.to_global_id }

    context 'when the scanner is persisted' do
      it 'creates the scanner Global ID' do
        expect(subject.to_s).to eq("gid://gitlab/Vulnerabilities::Scanner/#{scanner.id}")
      end
    end

    context 'when the scanner is not persisted' do
      let(:scanner) { build(:vulnerabilities_scanner) }

      it 'does not create the scanner Global ID' do
        expect(subject).to be_nil
      end
    end
  end

  describe '#report_type_humanized' do
    where(:report_type, :report_type_humanized) do
      'dast'                | 'DAST'
      'sast'                | 'SAST'
      'api_fuzzing'         | 'API Fuzzing'
      'dependency_scanning' | 'Dependency Scanning'
      nil                   | ''
    end

    with_them do
      before do
        scanner.scan_type = report_type
      end

      subject { presenter.report_type_humanized }

      it { is_expected.to eq(report_type_humanized) }
    end
  end
end
