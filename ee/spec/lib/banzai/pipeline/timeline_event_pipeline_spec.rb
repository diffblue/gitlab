# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::TimelineEventPipeline do
  let_it_be(:project) { create(:project) }

  describe '.reference_filters' do
    it 'contains required reference filters' do
      expect(described_class.reference_filters).to contain_exactly(
        *Banzai::Pipeline::GfmPipeline.reference_filters
      )
    end
  end

  describe '.to_html' do
    subject(:output) { described_class.to_html(markdown, project: project) }

    context 'when markdown contains font style transformations' do
      let(:markdown) { '**bold** _italic_ `code`'}

      it { is_expected.to eq('<p><strong>bold</strong> <em>italic</em> <code>code</code></p>') }
    end

    context 'when markdown contains banned HTML tags' do
      let(:markdown) { '<div>div</div><h1>h1</h1>'}

      it 'filters out banned tags' do
        is_expected.to eq(' div  h1 ')
      end
    end

    context 'when markdown contains links' do
      let(:markdown) { '[GitLab](https://gitlab.com)' }

      it { is_expected.to eq(%q(<p><a href="https://gitlab.com" target="_blank">GitLab</a></p>)) }
    end

    context 'when markdown contains images' do
      let(:markdown) { '![Name](/path/to/image.png)' }

      it 'replaces image with a link to the image' do
        is_expected.to eq(%q{<p><a class="with-attachment-icon" href="/path/to/image.png" target="_blank">Name</a></p>})
      end
    end

    context 'when markdown contains emojis' do
      let(:markdown) { ':+1:👍'}

      it { is_expected.to eq('<p>👍👍</p>') }
    end

    context 'when markdown contains a reference to an issue' do
      let!(:issue) { create(:issue, project: project) }
      let(:markdown) { "issue ##{issue.iid}" }

      it 'contains a link to the issue' do
        is_expected.to match(%r(<p>issue <a\shref="[\w\/]+-\/issues\/#{issue.iid}".*>##{issue.iid}<\/a><\/p>))
      end
    end

    context 'when markdown contains a reference to a merge request' do
      let!(:mr) { create(:merge_request, source_project: project, target_project: project) }
      let(:markdown) { "MR !#{mr.iid}" }

      it 'contains a link to the merge request' do
        is_expected.to match(%r(<p>MR <a\shref="[\w\/]+-\/merge_requests\/#{mr.iid}".*>!#{mr.iid}<\/a><\/p>))
      end
    end
  end
end
