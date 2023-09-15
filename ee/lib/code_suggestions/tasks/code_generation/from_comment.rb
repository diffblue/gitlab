# frozen_string_literal: true

module CodeSuggestions
  module Tasks
    module CodeGeneration
      class FromComment < CodeSuggestions::Tasks::Base
        extend ::Gitlab::Utils::Override

        GATEWAY_PROMPT_VERSION = 2

        # https://cloud.google.com/vertex-ai/docs/generative-ai/code/code-models-overview
        SUPPORTED_LANGUAGES = {
          "C" => %w[c],
          "C++" => %w[cc cpp],
          "C#" => %w[cs],
          "Clojure" => %w[clj cljs cljc],
          "Dart" => %w[dart],
          "Elixir" => %w[ex],
          "Erlang" => %w[erl],
          "Fortran" => %w[f],
          "Go" => %w[go],
          "GoogleSQL" => %w[sql],
          "Groovy" => %w[groovy],
          "Haskell" => %w[hs],
          "HTML" => %w[html],
          "Java" => %w[java],
          "JavaScript" => %w[js],
          "Kotlin" => %w[kt kts],
          "Lean (proof assistant)" => %w[lean],
          "Objective-C" => %w[m],
          "OCaml" => %w[ml],
          "Perl" => %w[pl],
          "PHP" => %w[php],
          "Python" => %w[py],
          "Ruby" => %w[rb],
          "Rust" => %w[rs],
          "Scala" => %w[scala],
          "Shell script" => %w[sh],
          "Solidity" => %w[sol],
          "Swift" => %w[swift],
          "TypeScript" => %w[ts],
          "Verilog" => %w[v]
        }.freeze

        override :endpoint_name
        def endpoint_name
          'generations'
        end

        override :body
        def body
          unsafe_passthrough_params.merge(
            prompt_version: GATEWAY_PROMPT_VERSION,
            prompt: prompt
          ).to_json
        end

        private

        def file_name
          params.dig(:current_file, :file_name).to_s
        end

        def prompt
          extension = File.extname(file_name).delete_prefix('.')
          language = SUPPORTED_LANGUAGES.find { |_, extensions| extensions.include?(extension) }&.first
          file_path_info = File.path(file_name)

          <<~PROMPT
            This is a task to write new #{language} code in a file '#{file_path_info}' based on a given description.
            You get first the already existing code file and then the description of the code that needs to be created.
            It is your task to write valid and working #{language} code.
            Only return in your response new code.

            Already existing code:

            ```#{extension}
            #{params[:prefix]}
            ```

            Create new code for the following description:
            `#{params[:instruction]}`
          PROMPT
        end
      end
    end
  end
end
