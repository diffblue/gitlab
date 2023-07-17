# frozen_string_literal: true

require 'csv'

module Gitlab
  module PackageMetadata
    module Connector
      DataFileError = Class.new(StandardError)

      class BaseDataFile
        include Enumerable
        include Gitlab::Utils::StrongMemoize

        attr_reader :sequence, :chunk

        def initialize(io, sequence, chunk)
          @io = io
          @sequence = sequence
          @chunk = chunk
        end

        def each
          io.each_line do |line|
            obj = parse(line)
            yield obj if obj
          end
        end

        def checkpoint?(checkpoint)
          checkpoint.sequence == sequence && checkpoint.chunk == chunk
        end

        def file_suffix
          self.class.file_suffix
        end

        def to_s
          "#{sequence}/#{chunk}.#{file_suffix}"
        end
        strong_memoize_attr :to_s

        private

        attr_reader :io

        def parse(_text)
          raise NoMethodError, 'abstract class does not implement parse'
        end
      end
    end
  end
end
