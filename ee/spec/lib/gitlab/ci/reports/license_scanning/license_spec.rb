# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::LicenseScanning::License do
  describe 'url', feature_category: :software_composition_analysis do
    subject { described_class.new(id: id, name: name, url: url).url }

    context 'with empty url' do
      let(:url) { '' }

      context 'with SPDX id' do
        let(:id) { 'MIT-0' }
        let(:name) { 'MIT No Attibution' }

        it 'returns a SPDX url' do
          is_expected.to eq('https://spdx.org/licenses/MIT-0.html')
        end
      end

      context 'with unknown license' do
        let(:id) { 'unknown' }
        let(:name) { 'Unknown' }

        it 'does not return a url' do
          is_expected.to be_nil
        end
      end

      context 'with custom license' do
        let(:id) { nil }
        let(:name) { 'Ruby Ruby Ruby' }

        it 'does not return a url' do
          is_expected.to be_nil
        end
      end

      # NOTE: the URL leads to 404, but non SPDX id is a rare case itself
      # this will be addressed in
      # https://gitlab.com/gitlab-org/gitlab/-/issues/410389
      context 'with non-SPDX id' do
        let(:id) { 'CUSTOM_ID' }
        let(:name) { 'CUSTOM LICENSE' }

        it 'returns a SPDX url' do
          is_expected.to eq('https://spdx.org/licenses/CUSTOM_ID.html')
        end
      end
    end

    context 'with url' do
      let(:id) { 'MIT' }
      let(:name) { 'MIT License' }
      let(:url) { 'https://opensource.org/licenses/mit' }

      it 'returns original url' do
        is_expected.to eq(url)
      end
    end
  end

  describe 'equality', feature_category: :security_policy_management do
    let(:blank) { described_class.new(id: nil, name: nil, url: nil) }
    let(:v1_mit) { described_class.new(id: nil, name: 'MIT', url: '') }
    let(:v1_apache) { described_class.new(id: nil, name: 'Apache 2.0', url: '') }
    let(:v2_mit) { described_class.new(id: 'MIT', name: 'MIT', url: '') }
    let(:v2_apache) { described_class.new(id: 'Apache-2.0', name: 'Apache 2.0', url: '') }

    describe '#eql?' do
      it { expect([v1_mit, v1_apache] - [v2_mit, v2_apache]).to be_empty }
      it { expect([v2_apache, v2_mit] & [v2_mit]).to match_array([v2_mit]) }
      it { expect([v2_apache, v2_mit] - [v1_apache, v1_mit]).to be_empty }
      it { expect([v2_apache] & [v2_mit]).to be_empty }
      it { expect([v2_apache] - [v1_apache]).to be_empty }
      it { expect([v2_apache] - [v1_mit]).to match_array([v2_apache]) }
      it { expect(blank).not_to eql(v1_mit) }
      it { expect(blank).not_to eql(v2_mit) }
      it { expect(blank).to eql(blank) }
      it { expect(v1_mit).not_to eql(blank) }
      it { expect(v1_mit).not_to eql(v1_apache) }
      it { expect(v1_mit).not_to eql(v2_apache) }
      it { expect(v1_mit).to eql(v1_mit) }
      it { expect(v1_mit).to eql(v2_mit) }
      it { expect(v2_mit).not_to eql(blank) }
      it { expect(v2_mit).not_to eql(v1_apache) }
      it { expect(v2_mit).not_to eql(v2_apache) }
      it { expect(v2_mit).to eql(v1_mit) }
      it { expect(v2_mit).to eql(v2_mit) }
      it { expect(v2_mit).to eql(described_class.new(id: v2_mit.id, name: '', url: '')) }
    end

    describe '#hash' do
      it { expect(blank.hash).to eql(blank.dup.hash) }
      it { expect(v1_mit.hash).to eql(v1_mit.dup.hash) }
      it { expect(v2_mit.hash).to eql(v2_mit.dup.hash) }
    end
  end

  describe '#canonical_id', feature_category: :security_policy_management do
    context 'when the license was produced from a v1 report' do
      subject { described_class.new(id: nil, name: 'MIT License', url: nil) }

      it { expect(subject.canonical_id).to eql(subject.name.downcase) }
    end

    context 'when the name matches a known legacy software license name' do
      where(:name, :spdx_id) do
        [
          ['AGPL-1.0', 'AGPL-1.0'],
          ['AGPL-3.0', 'AGPL-3.0'],
          ['Apache 2.0', 'Apache-2.0'],
          ['Artistic-2.0', 'Artistic-2.0'],
          ['BSD', 'BSD-4-Clause'],
          ['CC0 1.0 Universal', 'CC0-1.0'],
          ['CDDL-1.0', 'CDDL-1.0'],
          ['CDDL-1.1', 'CDDL-1.1'],
          ['EPL-1.0', 'EPL-1.0'],
          ['EPL-2.0', 'EPL-2.0'],
          ['GPLv2', 'GPL-2.0'],
          ['GPLv3', 'GPL-3.0'],
          %w[ISC ISC],
          ['LGPL', 'LGPL-3.0-only'],
          ['LGPL-2.1', 'LGPL-2.1'],
          %w[MIT MIT],
          ['Mozilla Public License 2.0', 'MPL-2.0'],
          %w[MS-PL MS-PL],
          %w[MS-RL MS-RL],
          ['New BSD', 'BSD-3-Clause'],
          ['Python Software Foundation License', 'Python-2.0'],
          %w[ruby Ruby],
          ['Simplified BSD', 'BSD-2-Clause'],
          %w[WTFPL WTFPL],
          %w[Zlib Zlib]
        ]
      end

      with_them do
        subject { described_class.new(id: nil, name: name, url: nil) }

        it { expect(subject.id).to eql(spdx_id) }
        it { expect(subject.canonical_id).to eql(spdx_id) }
      end
    end

    context 'when the license was produced from a v2 report' do
      subject { described_class.new(id: 'MIT', name: 'MIT License', url: nil) }

      it { expect(subject.canonical_id).to eql(subject.id) }
    end
  end
end
