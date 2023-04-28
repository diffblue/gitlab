# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      module Templates
        class GenerateTestFile
          def self.get_options(merge_request, path)
            prompt = <<-TEMPLATE
            Write unit tests for #{path} to ensure its proper functioning but only if the file contains code
            """
            #{Gitlab::Llm::OpenAi::Templates::GenerateTestFile.get_diff_file_content(merge_request, path)}
            """
            TEMPLATE

            {
              content: prompt,
              temperature: 0.2
            }
          end

          def self.get_diff_file_content(merge_request, path)
            file = merge_request.diffs.diff_files.find { |file| file.paths.include?(path) }

            file&.blob&.data
          end
        end
      end
    end
  end
end
