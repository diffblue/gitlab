# frozen_string_literal: true

namespace :tanuki_emoji do
  desc 'Generates Emoji SHA256 digests'

  task aliases: :environment do
    aliases = {}

    TanukiEmoji.index.all.each do |emoji|
      emoji.aliases.each do |emoji_alias|
        aliases[TanukiEmoji::Character.format_name(emoji_alias)] = emoji.name
      end
    end

    aliases_json_file = File.join(Rails.root, 'fixtures', 'emojis', 'aliases.json')
    File.open(aliases_json_file, 'w') do |handle|
      handle.write(Gitlab::Json.pretty_generate(aliases, indent: '   ', space: '', space_before: ''))
    end
  end

  task digests: :environment do
    require 'digest/sha2'

    digest_emoji_map = {}
    emojis_map = {}

    TanukiEmoji.index.all.each do |emoji|
      emoji_path = File.join(TanukiEmoji.images_path, emoji.image_name)

      digest_entry = {
        category: emoji.category,
        moji: emoji.codepoints,
        description: emoji.description,
        unicodeVersion: emoji.unicode_version,
        digest: Digest::SHA256.file(emoji_path).hexdigest
      }

      digest_emoji_map[emoji.name] = digest_entry

      # Our new map is only characters to make the json substantially smaller
      emoji_entry = {
        c: emoji.category,
        e: emoji.codepoints,
        d: emoji.description,
        u: emoji.unicode_version
      }

      emojis_map[emoji.name] = emoji_entry
    end

    digests_json = File.join(Rails.root, 'fixtures', 'emojis', 'digests.json')
    File.open(digests_json, 'w') do |handle|
      handle.write(Gitlab::Json.pretty_generate(digest_emoji_map))
    end

    emojis_json = File.join(Rails.root, 'public', '-', 'emojis', '1', 'emojis.json')
    File.open(emojis_json, 'w') do |handle|
      handle.write(Gitlab::Json.pretty_generate(emojis_map))
    end
  end

  # This task will generate a standard and Retina sprite of all of the current
  # Gemojione Emojis, with the accompanying SCSS map.
  #
  # It will not appear in `rake -T` output, and the dependent gems are not
  # included in the Gemfile by default, because this task will only be needed
  # occasionally, such as when new Emojis are added to Gemojione.
  task sprite: :environment do
    begin
      require 'mini_magick'
      require 'sprite_factory'
      # Sprite-Factory still requires rmagick, but maybe could be migrated to support minimagick
      # Upstream issue: https://github.com/jakesgordon/sprite-factory/issues/47#issuecomment-929302890
      require 'rmagick'
    rescue LoadError
      # noop
    end

    check_requirements!

    SIZE   = 20
    RETINA = SIZE * 2

    # Update these values to the width and height of the spritesheet when
    # new emoji are added.
    SPRITESHEET_WIDTH = 860
    SPRITESHEET_HEIGHT = 840

    # Re-create the assets folder and copy emojis renaming them to use name instead of unicode hex
    emoji_dir = "app/assets/images/emoji"
    FileUtils.rm_rf(emoji_dir)
    FileUtils.mkdir_p(emoji_dir, mode: 0700)

    TanukiEmoji.index.all.each do |emoji|
      source = File.join(TanukiEmoji.images_path, emoji.image_name)
      destination = File.join(emoji_dir, "#{emoji.name}.png")

      FileUtils.cp(source, destination)
    end

    Dir.mktmpdir do |tmpdir|
      FileUtils.cp_r(File.join(emoji_dir, '.'), tmpdir)

      Dir.chdir(tmpdir) do
        Dir["**/*.png"].each do |png|
          tmp_image_path = File.join(tmpdir, png)
          resize!(tmp_image_path, SIZE)
        end
      end

      style_path = Rails.root.join(*%w(app assets stylesheets framework emoji_sprites.scss))

      # Combine the resized assets into a packed sprite and re-generate the SCSS
      SpriteFactory.cssurl = "image-url('$IMAGE')"
      SpriteFactory.run!(tmpdir, {
        output_style: style_path,
        output_image: "app/assets/images/emoji.png",
        selector:     '.emoji-',
        style:        :scss,
        nocomments:   true,
        pngcrush:     true,
        layout:       :packed
      })

      # SpriteFactory's SCSS is a bit too verbose for our purposes here, so
      # let's simplify it
      system(%Q(sed -i '' "s/width: #{SIZE}px; height: #{SIZE}px; background: image-url('emoji.png')/background-position:/" #{style_path}))
      system(%Q(sed -i '' "s/ no-repeat//" #{style_path}))
      system(%Q(sed -i '' "s/ 0px/ 0/g" #{style_path}))

      # Append a generic rule that applies to all Emojis
      File.open(style_path, 'a') do |f|
        f.puts
        f.puts <<-CSS.strip_heredoc
        .emoji-icon {
          background-image: image-url('emoji.png');
          background-repeat: no-repeat;
          color: transparent;
          text-indent: -99em;
          height: #{SIZE}px;
          width: #{SIZE}px;

          @media only screen and (-webkit-min-device-pixel-ratio: 2),
                 only screen and (min--moz-device-pixel-ratio: 2),
                 only screen and (-o-min-device-pixel-ratio: 2/1),
                 only screen and (min-device-pixel-ratio: 2),
                 only screen and (min-resolution: 192dpi),
                 only screen and (min-resolution: 2dppx) {
            background-image: image-url('emoji@2x.png');
            background-size: #{SPRITESHEET_WIDTH}px #{SPRITESHEET_HEIGHT}px;
          }
        }
        CSS
      end
    end

    # Now do it again but for Retina
    Dir.mktmpdir do |tmpdir|
      # Copy the Gemojione assets to the temporary folder for resizing
      FileUtils.cp_r(File.join(emoji_dir, '.'), tmpdir)

      Dir.chdir(tmpdir) do
        Dir["**/*.png"].each do |png|
          tmp_image_path = File.join(tmpdir, png)
          resize!(tmp_image_path, RETINA)
        end
      end

      # Combine the resized assets into a packed sprite and re-generate the SCSS
      SpriteFactory.run!(tmpdir, {
        output_image: "app/assets/images/emoji@2x.png",
        style:        false,
        nocomments:   true,
        pngcrush:     true,
        layout:       :packed
      })
    end
  end

  def check_requirements!
    return if defined?(Magick)

    puts <<-MSG.strip_heredoc
      This task is disabled by default and should only be run when the TanukiEmoji
      gem is updated with new Emojis.

      To enable this task, *temporarily* add the following lines to Gemfile and
      re-bundle:

      gem 'rmagick', '~> 3.2'

      It depends on ImageMagick 6, which can be installed via HomeBrew with:

      brew unlink imagemagick
      brew install imagemagick@6 && brew link imagemagick@6 --force
    MSG

    exit 1
  end

  def resize!(image_path, size)
    # Resize the image in-place, save it, and free the object
    image = MiniMagick::Image.open(image_path)
    image.quality(100)
    image.resize("#{size}x#{size}")
    image.write(image_path)
  end
end
