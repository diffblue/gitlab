# frozen_string_literal: true

module CodeSuggestions
  module Prompts
    class Base
      include Gitlab::Utils::StrongMemoize

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

      def initialize(params)
        @params = params
      end

      private

      attr_reader :params

      def file_name
        params.dig(:current_file, :file_name).to_s
      end

      def file_path_info
        File.path(file_name)
      end

      def extension
        File.extname(file_name).delete_prefix('.')
      end
      strong_memoize_attr :extension

      def language
        SUPPORTED_LANGUAGES.find { |_, extensions| extensions.include?(extension) }&.first
      end
      strong_memoize_attr :language

      def prefix
        params.dig(:current_file, :content_above_cursor)
      end

      def suffix
        params.dig(:current_file, :content_below_cursor)
      end
    end
  end
end
