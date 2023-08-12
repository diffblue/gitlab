# frozen_string_literal: true

namespace :gitlab do
  namespace :llm do
    namespace :embeddings do
      desc 'Extract the embeddings for selected questions into a fixture'
      task :extract_embeddings, [] => [:environment] do |_t, _args|
        questions = [
          "How do I change my password in GitLab",
          "How do I fork a project?",
          "How do I clone a repository?",
          "How do I create a project template?"
        ]

        openai_client = ::Gitlab::Llm::OpenAi::Client.new(User.first,
          request_timeout: ::Gitlab::Llm::TanukiBot::REQUEST_TIMEOUT)
        embedding_ids = questions
          .map { |q| ::Gitlab::Llm::TanukiBot.embedding_for_question(openai_client, q) }
          .flat_map { |e| ::Gitlab::Llm::TanukiBot.get_nearest_neighbors(e) }
          .filter_map { |h| h[:id] }

        sql = ::Embedding::TanukiBotMvc.select("*").where(id: embedding_ids).to_sql
        fixture_path = Rails.root.join("ee/spec/fixtures/embeddings")
        ::Embedding::TanukiBotMvc.connection.execute("COPY (#{sql}) TO '#{fixture_path}'")

        puts "Don't forget to commit the generated `ee/spec/fixtures/embeddings`."
      end

      # Warning: the task will TRUNCATE the embeddings table.
      desc 'Seed embeddings test database with pre-generated embeddings'
      task :seed_pre_generated, [] => [:environment] do |_t, _args|
        sha = 'f7bfb0bd48fbb33c620146f5df5a88d54e489127'
        number_of_rows = 12739
        url = "https://gitlab.com/gitlab-org/enablement-section/tanuki-bot/-/raw/#{sha}/pgvector/tanuki_bot_mvc.json?inline=false"

        Dir.mktmpdir do |dir|
          WebMock.allow_net_connect! if ENV['RAILS_ENV'] == 'test'

          puts "> Fetching `tanuki_bot_mvc.json` file size"
          content_length = Gitlab::HTTP.head(url).headers.fetch('content-length').to_i

          File.open("#{dir}/tanuki_bot_mvc.json", "wb") do |file|
            puts "> Downloading `tanuki_bot_mvc.json` containing pre-generated embeddings"
            cursor = 0
            i = 0
            Gitlab::HTTP.get(url, stream_body: true) do |fragment|
              file.write(fragment)
              cursor += fragment.length
              i += 1
              if i % 1000 == 0 || cursor == content_length
                puts "#{cursor / (2**20)}MiB (#{((cursor / content_length.to_f) * 100).round(2)}%)"
              end
            end
          end

          puts "> Reading and adding embeddings from `tanuki_bot_mvc.json`"
          ::Embedding::TanukiBotMvc.connection.execute("TRUNCATE TABLE #{::Embedding::TanukiBotMvc.table_name}")

          i = 0
          File.open("#{dir}/tanuki_bot_mvc.json").each_line do |line|
            attributes = ::Gitlab::Json.parse(line)
            ::Embedding::TanukiBotMvc.create!(attributes)
            i += 1

            count = ::Embedding::TanukiBotMvc.count
            if i % 100 == 0 || i == number_of_rows
              puts "#{count}/#{number_of_rows} (#{((count / number_of_rows.to_f) * 100).round(2)}%)"
            end
          end

          # Delete records with no meaningful content
          ::Embedding::TanukiBotMvc.where.not("content ~ ?", '\w').delete_all
          # Delete records without titles as these likely no longer exist
          ::Embedding::TanukiBotMvc.where("metadata -> 'title' IS NULL").delete_all

          puts "Number of records: #{::Embedding::TanukiBotMvc.count}"
        end
      end
    end
  end
end
