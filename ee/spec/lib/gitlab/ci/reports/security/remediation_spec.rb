# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::Security::Remediation do
  let(:diff) { 'foo' }
  let(:remediation) { build(:ci_reports_security_remediation, diff: diff) }

  describe '#diff_file' do
    subject { remediation.diff_file.read }

    it { is_expected.to eq(diff) }
  end

  describe '#checksum' do
    let(:expected_checksum) { '2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae' }

    subject { remediation.checksum }

    it { is_expected.to eq(expected_checksum) }
  end

  describe '#byte_offsets' do
    subject { remediation.byte_offsets }

    context 'when the start and end bytes are missing' do
      let(:remediation) { build(:ci_reports_security_remediation) }

      it { is_expected.to be_nil }
    end

    context 'when the start and end bytes are present' do
      let(:remediation) { build(:ci_reports_security_remediation, start_byte: 0, end_byte: 100) }

      it { is_expected.to eq({ start_byte: 0, end_byte: 100 }) }
    end
  end
end
