# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Embeddings::Utils::BaseContentParser, feature_category: :duo_chat do
  let(:max_chars_per_embedding) { 150 }
  let(:min_chars_per_embedding) { 5 }
  let(:parser) { described_class.new(min_chars_per_embedding, max_chars_per_embedding) }

  describe '#parse_and_split' do
    let(:content) { 'Something to split' }
    let(:source_name) { '/doc/path/to/file.md' }
    let(:source_type) { 'doc' }

    subject(:parse_and_split) { parser.parse_and_split(content, source_name, source_type) }

    it 'calls #parse_content_and_metadata' do
      expect(parser).to receive(:parse_content_and_metadata).and_return([content, {}, nil]).once

      expect(parse_and_split.count).to eq(1)
      expect(parse_and_split.first[:content]).to eq(content)
      expect(parse_and_split.first[:metadata]).to eq({})
    end

    context 'when the content is less than the maximum characters' do
      it 'returns the full content' do
        expect(parse_and_split.count).to eq(1)
        expect(parse_and_split.first[:content]).to eq(content)
      end
    end

    context 'when the content is more than the maximum characters per slice' do
      let(:max_chars_per_embedding) { 3 }

      it 'does not return any items' do
        expect(parse_and_split).to eq([])
      end

      context 'when slices are more than the minimum char length' do
        let(:min_chars_per_embedding) { 2 }

        it 'does not return any items' do
          expect(parse_and_split.count).to eq(6)
          expect(parse_and_split.pluck(:content)).to match_array(["Som", "eth", "ing", " to", " sp", "lit"])
        end

        context 'when the last slice is less than the minimum' do
          let(:content) { 'Some thing at' }

          it 'throws away the last slice' do
            expect(parse_and_split.count).to eq(4)
            expect(parse_and_split.pluck(:content)).to match_array(["Som", "e t", "hin", "g a"])
          end
        end

        context 'with newlines' do
          let(:content) { "Some\ntext\nwith\nnewlines and characters" }
          let(:max_chars_per_embedding) { 10 }

          it 'splits according to newlines and then characters' do
            expect(parse_and_split.count).to eq(5)
            expect(parse_and_split.pluck(:content)).to match_array(
              ["Some\ntext", "with", "newlines a", "nd charact", "ers"]
            )
          end

          context 'when the block is smaller than the minimum char length' do
            let(:content) { "From\nabc \nto\nnewlines" }
            let(:max_chars_per_embedding) { 4 }
            let(:min_chars_per_embedding) { 3 }

            it 'splits according to newlines and then characters' do
              expect(parse_and_split.count).to eq(4)
              expect(parse_and_split.pluck(:content)).to match_array(["From", "abc ", "newl", "ines"])
            end
          end
        end
      end
    end
  end

  describe '#parse_content_and_metadata' do
    let(:input_content) { "# Heading 1\nSome content\n" }
    let(:source_name) { '/doc/path/to/file.md' }
    let(:source_type) { 'doc' }

    subject(:parse) { parser.parse_content_and_metadata(input_content, source_name, source_type) }

    it 'returns title, source, source_type and url' do
      _content, metadata, url = parse

      expect(metadata.keys).to match_array(%w[title source source_type])
      expect(metadata['title']).to eq(parser.title(input_content))
      expect(metadata['source']).to eq(source_name)
      expect(metadata['source_type']).to eq(source_type)
      expect(url).to eq(parser.url(source_name, source_type))
    end

    context 'when content contains metadata' do
      let(:input_content) { "---\ninfo: 'Test'\ntype: 'reference'---\ntext" }

      it 'extracts metadata from the content' do
        content, metadata, _url = parse

        expect(metadata.keys).to match_array(%w[info type title source source_type])
        expect(metadata['info']).to eq('Test')
        expect(metadata['type']).to eq('reference')
        expect(content).to eq('text')
        expect(metadata['title']).to eq(parser.title(content))
      end
    end
  end

  describe '#title' do
    using RSpec::Parameterized::TableSyntax

    where(:content, :title) do
      "# A title\n"                     | "A title"
      "\n# A title\n"                   | "A title"
      "## A subtitle\n"                 | "A subtitle"
      "# A title **(PREMIUM SELF)**\n"  | "A title"
      "A title\n"                       | nil
      "# A title"                       | nil
      "# A title **(PREMIUM SELF)**"    | nil
    end

    with_them do
      it 'returns the correct title' do
        expect(parser.title(content)).to eq(title)
      end
    end
  end

  describe '#url' do
    it 'returns the correct url' do
      expect(parser.url('/doc/path/to/file.md', 'doc'))
        .to eq(::Gitlab::Routing.url_helpers.help_page_url('path/to/file'))
    end

    it 'returns nil if the source is not doc' do
      expect(parser.url('/blog/path/to/file.md', 'blog')).to be_nil
    end
  end
end
