# frozen_string_literal: true

require 'yaml'

module Tooling
  module FindCodeowners
    module_function

    def run
      ls_files = git_ls_files

      load_definitions.each do |section, group_defintions|
        puts section

        group_defintions.each do |group, allow:, deny:|
          matched_files = ls_files.each_line.select do |line|
            allow.find do |pattern|
              path = "/#{line.chomp}"

              path_matches?(pattern, path) &&
                deny.none? { |pattern| path_matches?(pattern, path) }
            end
          end

          consolidated = consolidate_paths(matched_files)
          consolidated_again = consolidate_paths(consolidated)

          while consolidated_again.size < consolidated.size
            consolidated = consolidated_again
            consolidated_again = consolidate_paths(consolidated)
          end

          consolidated.each do |file|
            puts "/#{file.chomp} #{group}"
          end
        end
      end
    end

    def load_definitions
      result = load_config

      result.each do |section, group_defintions|
        group_defintions.each do |group, definitions|
          definitions.transform_values! do |keywords:, patterns:|
            keywords.flat_map do |keyword|
              patterns.map do |pattern|
                pattern % { keyword: keyword }
              end
            end
          end
        end
      end

      result
    end

    def load_config
      config_path = "#{__dir__}/../../config/CODEOWNERS.yml"

      if YAML.respond_to?(:safe_load_file) # Ruby 3.0+
        YAML.safe_load_file(config_path, symbolize_names: true)
      else
        YAML.safe_load(File.read(config_path), symbolize_names: true)
      end
    end

    # Copied and modified from ee/lib/gitlab/code_owners/file.rb
    def path_matches?(pattern, path)
      # `FNM_DOTMATCH` makes sure we also match files starting with a `.`
      # `FNM_PATHNAME` makes sure ** matches path separators
      flags = ::File::FNM_DOTMATCH | ::File::FNM_PATHNAME

      # BEGIN extension
      flags |= ::File::FNM_EXTGLOB
      # END extension

      ::File.fnmatch?(pattern, path, flags)
    end

    def consolidate_paths(matched_files)
      matched_files.group_by(&File.method(:dirname)).flat_map do |dir, files|
        # First line is the dir itself
        if find_dir_maxdepth_1(dir).lines.drop(1).sort == files.sort
          "#{dir}\n"
        else
          files
        end
      end.sort
    end

    def git_ls_files
      `git ls-files`
    end

    def find_dir_maxdepth_1(dir)
      `find #{dir} -maxdepth 1`
    end
  end
end
