# frozen_string_literal: true

module Gitlab
  module Emoji
    extend self

    def emojis_by_moji
      TanukiEmoji.index.instance_variable_get(:@codepoints_index)
    end

    def emojis_unicodes
      emojis_by_moji.keys
    end

    def emojis_aliases
      @emoji_aliases ||= Gitlab::Json.parse(File.read(Rails.root.join('fixtures', 'emojis', 'aliases.json')))
    end

    def emoji_filename(name)
      TanukiEmoji.find_by_alpha_code(name).image_name
    end

    def emoji_unicode_filename(moji)
      TanukiEmoji.find_by_codepoints(moji).image_name
    end

    def normalize_emoji_name(name)
      emojis_aliases[name] || name
    end

    def emoji_image_tag(name, src)
      image_options = {
        class:  'emoji',
        src:    src,
        title:  ":#{name}:",
        alt:    ":#{name}:",
        height: 20,
        width:  20,
        align:  'absmiddle'
      }

      ActionController::Base.helpers.tag(:img, image_options)
    end

    def emoji_exists?(name)
      TanukiEmoji.find_by_alpha_code(name)
    end

    # CSS sprite fallback takes precedence over image fallback
    # @param [TanukiEmoji::Character] emoji
    # @param [Hash] options
    def gl_emoji_tag(emoji, options = {})
      return unless emoji

      data = {
        name: emoji.name,
        unicode_version: emoji.unicode_version
      }
      options = { title: emoji.description, data: data }.merge(options)

      ActionController::Base.helpers.content_tag('gl-emoji', emoji.codepoints, options)
    end

    def custom_emoji_tag(name, image_source)
      data = {
        name: name
      }

      ActionController::Base.helpers.content_tag('gl-emoji', title: name, data: data) do
        emoji_image_tag(name, image_source).html_safe
      end
    end
  end
end
