# frozen_string_literal: true

module IpynbDiff
  require 'oj'

  # Creates a symbol map for a ipynb file (JSON format)
  class SymbolMap
    class << self
      def parser
        @parser ||= SymbolMap.new.tap { |p| Oj::Parser.saj.handler = p }
      end

      def parse(notebook, *args)
        parser.parse(notebook)
      end
    end

    attr_accessor :symbols

    def hash_start(key, line, column)
      add_symbol(key_or_index(key), line)
    end

    def hash_end(key, line, column)
      @current_path.pop
    end

    def array_start(key, line, column)
      @current_array_index << 0

      add_symbol(key, line)
    end

    def array_end(key, line, column)
      @current_path.pop
      @current_array_index.pop
    end

    def add_value(value, key, line, column)
      add_symbol(key_or_index(key), line)

      @current_path.pop
    end

    def parse(notebook)
      reset
      Oj::Parser.saj.parse(notebook)
      symbols
    end

    private

    def add_symbol(symbol, line)
      @symbols[@current_path.append(symbol).join('.')] = line if symbol
    end

    def key_or_index(key)
      if key.nil? || key.empty? # value in an array
        if @current_path.empty?
          @current_path = ['']
          return nil
        end

        symbol = @current_array_index.last
        @current_array_index[-1] += 1
        symbol
      else
        key
      end
    end

    def reset
      @current_path = []
      @current_path_line_starts = []
      @symbols = {}
      @current_array_index = []
    end
  end
end
