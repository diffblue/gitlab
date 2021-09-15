# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Emoji do
  let_it_be(:emojis_by_moji) { TanukiEmoji.index.all.index_by(&:codepoints) }
  let_it_be(:emojis_aliases) { Gitlab::Json.parse(File.read(Rails.root.join('fixtures', 'emojis', 'aliases.json'))) }

  describe '.emojis_aliases' do
    it 'returns emoji aliases' do
      emoji_aliases = described_class.emojis_aliases

      expect(emoji_aliases).to eq(emojis_aliases)
    end
  end

  describe '.emoji_filename' do
    it 'returns emoji filename' do
      # "100" => {"unicode"=>"1F4AF"...}
      emoji_filename = described_class.emoji_filename('100')

      expect(emoji_filename).to eq("emoji_u#{TanukiEmoji.find_by_alpha_code('100').hex}.png")
    end
  end

  describe '.emoji_unicode_filename' do
    it 'returns emoji unicode filename' do
      emoji_unicode_filename = described_class.emoji_unicode_filename('💯')

      expect(emoji_unicode_filename).to eq("emoji_u#{TanukiEmoji.find_by_codepoints('💯').hex}.png")
    end
  end

  describe '.normalize_emoji_name' do
    it 'returns same name if not found in aliases' do
      emoji_name = described_class.normalize_emoji_name('random')

      expect(emoji_name).to eq('random')
    end

    it 'returns name if name found in aliases' do
      emoji_name = described_class.normalize_emoji_name('small_airplane')

      expect(emoji_name).to eq(emojis_aliases['small_airplane'])
    end
  end

  describe '.emoji_image_tag' do
    it 'returns emoji image tag' do
      emoji_image = described_class.emoji_image_tag('emoji_one', 'src_url')

      expect(emoji_image).to eq("<img class=\"emoji\" src=\"src_url\" title=\":emoji_one:\" alt=\":emoji_one:\" height=\"20\" width=\"20\" align=\"absmiddle\" />")
    end

    it 'escapes emoji image attrs to prevent XSS' do
      xss_payload = "<script>alert(1)</script>"
      escaped_xss_payload = html_escape(xss_payload)

      emoji_image = described_class.emoji_image_tag(xss_payload, 'http://aaa#' + xss_payload)

      expect(emoji_image).to eq("<img class=\"emoji\" src=\"http://aaa##{escaped_xss_payload}\" title=\":#{escaped_xss_payload}:\" alt=\":#{escaped_xss_payload}:\" height=\"20\" width=\"20\" align=\"absmiddle\" />")
    end
  end

  describe '.emoji_exists?' do
    it 'returns true if the name exists' do
      emoji_exists = described_class.emoji_exists?('100')

      expect(emoji_exists).to be_truthy
    end

    it 'returns false if the name does not exist' do
      emoji_exists = described_class.emoji_exists?('random')

      expect(emoji_exists).to be_falsey
    end
  end

  describe '.gl_emoji_tag' do
    it 'returns gl emoji tag if emoji is found' do
      emoji = TanukiEmoji.find_by_alpha_code('small_airplane')
      gl_tag = described_class.gl_emoji_tag(emoji)

      expect(gl_tag).to eq('<gl-emoji title="small airplane" data-name="airplane_small" data-unicode-version="7.0">🛩</gl-emoji>')
    end

    it 'returns nil if emoji is not found' do
      emoji = TanukiEmoji.find_by_alpha_code('random')
      gl_tag = described_class.gl_emoji_tag(emoji)

      expect(gl_tag).to be_nil
    end
  end
end
