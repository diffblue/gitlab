# frozen_string_literal: true

namespace :gitlab do
  namespace :banzai do
    desc 'GitLab | Banzai | Render markdown using our FullPipeline (input will be requested)'
    task render: :environment do |_t|
      markdown = []

      puts "\nEnter markdown below, Ctrl-D to end (if you need blank lines, paste in the full text):"
      while buf = Readline.readline('', true)
        markdown << buf
      end

      puts "Rendering using Gitlab's FullPipeline...\n\n"
      puts Banzai::Pipeline::FullPipeline.to_html(markdown.join("\n"), project: nil)
    end
  end
end
