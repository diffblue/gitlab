# frozen_string_literal: true

require_relative '../../../../tooling/lib/tooling/find_codeowners'

RSpec.describe Tooling::FindCodeowners do
  let(:subject) { described_class.new }

  describe '#execute' do
    before do
      allow(subject).to receive(:git_ls_files).and_return(<<~LINES)
        dir/0/0/2/0
        dir/0/0/2/2
        dir/0/0/3
        dir/0/1
        dir/1
        dir/2
      LINES

      find_results = {
        'dir/0/0/2' => "dir/0/0/2\ndir/0/0/2/0\ndir/0/0/2/2\n",
        'dir/0/0' => "dir/0/0\ndir/0/0/2\ndir/0/0/3\n",
        'dir/0' => "dir/0\ndir/0/0\ndir/0/1\n",
        'dir' => "dir\ndir/0\ndir/1\ndir/2\n"
      }

      allow(subject).to receive(:find_dir_maxdepth_1) do |dir|
        find_results[dir]
      end

      allow(subject).to receive(:load_config).and_return(
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
      expect { subject.execute }.to output(<<~CODEOWNERS).to_stdout
        [Section name]
        /dir/0/0 @group
        /dir/2 @group
      CODEOWNERS
    end
  end

  describe '#load_definitions' do
    it 'expands the allow and deny list with keywords and patterns' do
      subject.__send__(:load_definitions).each do |section, group_defintions|
        group_defintions.each do |group, definitions|
          expect(definitions[:allow]).to be_an(Array)
          expect(definitions[:deny]).to be_an(Array)
        end
      end
    end

    it 'expands the auth group' do
      auth = subject.__send__(:load_definitions).dig(
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
      config = subject.__send__(:load_config)

      expect_hash_keys_to_be_symbols(config)
    end

    context 'when YAML has safe_load_file' do
      before do
        allow(YAML).to receive(:respond_to?).with(:safe_load_file).and_return(true)
      end

      it 'calls safe_load_file' do
        expect(YAML).to receive(:safe_load_file)

        subject.__send__(:load_config)
      end
    end

    context 'when YAML does not have safe_load_file' do
      before do
        allow(YAML).to receive(:respond_to?).with(:safe_load_file).and_return(false)
      end

      it 'calls load_file' do
        expect(YAML).to receive(:safe_load)

        subject.__send__(:load_config)
      end
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

      subject.__send__(:path_matches?, pattern, path)
    end
  end

  describe '#consolidate_paths' do
    before do
      allow(subject).to receive(:find_dir_maxdepth_1).and_return(<<~LINES)
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
        paths = subject.__send__(:consolidate_paths, input_paths)

        expect(paths).to eq(["dir\n"])
      end
    end

    context 'when the directory has different number of entries' do
      let(:input_paths) { %W[dir/0\n dir/1\n dir/2\n] }

      it 'returns the original paths' do
        paths = subject.__send__(:consolidate_paths, input_paths)

        expect(paths).to eq(input_paths)
      end
    end
  end

  describe '#find_dir_maxdepth_1' do
    it 'calls `find dir -maxdepth 1`' do
      expect(subject).to receive(:`).with('find tmp -maxdepth 1').and_call_original

      subject.__send__(:find_dir_maxdepth_1, 'tmp')
    end
  end

  describe '#git_ls_files' do
    it 'calls `git ls-files`' do
      expect(subject).to receive(:`).with('git ls-files').and_call_original

      subject.__send__(:git_ls_files)
    end
  end
end
