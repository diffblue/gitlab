# frozen_string_literal: true

require_relative '../../../../tooling/lib/tooling/find_codeowners'

RSpec.describe Tooling::FindCodeowners do
  describe '#run' do
    before do
      allow(described_class).to receive(:git_ls_files).and_return(<<~LINES)
        dir/0/0/0
        dir/0/0/2
        dir/0/1
        dir/1
        dir/2
      LINES

      find_results = {
        'dir/0/0' => "dir/0/0\ndir/0/0/0\ndir/0/0/2\n",
        'dir/0' => "dir/0\ndir/0/0/0\ndir/0/0/2\ndir/0/1\n",
        'dir' => "dir\ndir/0/0/0\ndir/0/0/2\ndir/0/1\ndir/1\ndir/2\n"
      }

      allow(described_class).to receive(:find_dir_maxdepth_1) do |dir|
        find_results[dir]
      end

      allow(described_class).to receive(:load_config).and_return(
        '[Section name]': {
          '@group': {
            allow: {
              keywords: ['dir'],
              patterns: ['/%{keyword}/**/*']
            },
            deny: {
              keywords: ['1'],
              patterns: ['**/%{keyword}']
            }
          }
        }
      )
    end

    it 'prints CODEOWNERS as configured' do
      expect { described_class.run }.to output(<<~CODEOWNERS).to_stdout
        [Section name]
        /dir/0/0 @group
        /dir/2 @group
      CODEOWNERS
    end
  end

  describe '#load_definitions' do
    it 'expands the allow and deny list with keywords and patterns' do
      described_class.load_definitions.each do |section, group_defintions|
        group_defintions.each do |group, definitions|
          expect(definitions[:allow]).to be_an(Array)
          expect(definitions[:deny]).to be_an(Array)
        end
      end
    end

    it 'expands the auth group' do
      auth = described_class.load_definitions.dig(
        :'[Authentication and Authorization]',
        :'@gitlab-org/manage/authentication-and-authorization')

      expect(auth).to eq(
        allow: %w[
          /{,ee/}app/**/*password*{/**/*,}
          /{,ee/}config/**/*password*{/**/*,}
          /{,ee/}lib/**/*password*{/**/*,}
          /{,ee/}app/**/*auth*{/**/*,}
          /{,ee/}config/**/*auth*{/**/*,}
          /{,ee/}lib/**/*auth*{/**/*,}
          /{,ee/}app/**/*token*{/**/*,}
          /{,ee/}config/**/*token*{/**/*,}
          /{,ee/}lib/**/*token*{/**/*,}
        ],
        deny: %w[
          **/*author.*{/**/*,}
          **/*author_*{/**/*,}
          **/*authored*{/**/*,}
          **/*authoring*{/**/*,}
          **/*.png*{/**/*,}
          **/*.svg*{/**/*,}
          **/*deploy_token*{/**/*,}
          **/*runner{,s}_token*{/**/*,}
          **/*job_token*{/**/*,}
          **/*tokenizer*{/**/*,}
          **/*filtered_search*{/**/*,}
        ]
      )
    end
  end

  describe '#load_config' do
    it 'loads the config with symbolized keys' do
      config = described_class.load_config

      expect_hash_keys_to_be_symbols(config)
    end

    def expect_hash_keys_to_be_symbols(object)
      if object.is_a?(Hash)
        object.each do |key, value|
          expect(key).to be_a(Symbol)

          expect_hash_keys_to_be_symbols(value)
        end
      end
    end
  end

  describe '#path_matches?' do
    let(:pattern) { 'pattern' }
    let(:path) { 'path' }

    it 'passes flags we are expecting to File.fnmatch?' do
      expected_flags =
        ::File::FNM_DOTMATCH | ::File::FNM_PATHNAME | ::File::FNM_EXTGLOB

      expect(File).to receive(:fnmatch?).with(pattern, path, expected_flags)

      described_class.path_matches?(pattern, path)
    end
  end

  describe '#consolidate_paths' do
    before do
      allow(described_class).to receive(:find_dir_maxdepth_1).and_return(<<~LINES)
        dir
        dir/0
        dir/2
        dir/3
        dir/1
      LINES
    end

    context 'when the directory has the same number of entries' do
      let(:input_paths) { %W[dir/0\n dir/1\n dir/2\n dir/3\n] }

      it 'consolidates into the directory' do
        paths = described_class.consolidate_paths(input_paths)

        expect(paths).to eq(["dir\n"])
      end
    end

    context 'when the directory has different number of entries' do
      let(:input_paths) { %W[dir/0\n dir/1\n dir/2\n] }

      it 'returns the original paths' do
        paths = described_class.consolidate_paths(input_paths)

        expect(paths).to eq(input_paths)
      end
    end
  end
end
