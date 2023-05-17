# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::RemediationsProxy, feature_category: :vulnerability_management do
  let(:dast_artifact) { create(:ci_job_artifact, :common_security_report) }
  let(:file) { dast_artifact.file }
  let(:model) { described_class.new(file) }

  describe '#by_byte_offsets' do
    # The following byte offsets are collected by parsing the related artifact with Oj::Introspect.
    # If the specs fail due to a change in the related artifact, you can collect them again by parsing
    # the artifact again and checking the `:__oj_introspect` keys for remediations.
    let(:remediation_1_byte_offsets) { [11842, 12008] }
    let(:remediation_2_byte_offsets) { [12015, 12181] }
    let(:remediation_3_byte_offsets) { remediation_2_byte_offsets }

    subject(:data_fragments) do
      model.by_byte_offsets([remediation_1_byte_offsets, remediation_2_byte_offsets, remediation_2_byte_offsets])
           .map(&:deep_symbolize_keys)
    end

    context 'when the file exists' do
      before do
        allow(file).to receive(:multi_read).and_call_original
      end

      it 'returns remediations by given byte offsets' do
        expect(data_fragments).to eq(
          [
            {
              diff: 'dG90YWxseSBsZWdpdCBkaWZm',
              summary: 'this remediates CVE-2137',
              fixes: [{ cve: 'CVE-2137' }]
            },
            {
              diff: 'dG90YWxseSBsZWdpdCBkaWZm',
              summary: 'this remediates CVE-2138',
              fixes: [{ cve: 'CVE-2138' }]
            },
            {
              diff: 'dG90YWxseSBsZWdpdCBkaWZm',
              summary: 'this remediates CVE-2138',
              fixes: [{ cve: 'CVE-2138' }]
            }
          ]
        )
      end

      it 'delegates the call to GitlabUploader#multi_read with unique offsets' do
        data_fragments

        expect(file).to have_received(:multi_read).once.with([remediation_1_byte_offsets, remediation_2_byte_offsets])
      end
    end

    context 'when the file is nil' do
      let(:file) { nil }

      it { is_expected.to be_empty }
    end
  end
end
