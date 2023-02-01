# frozen_string_literal: true

module Security
  class RemediationsProxy
    attr_reader :file

    def initialize(file)
      @file = file
    end

    def by_byte_offsets(byte_offsets)
      return [] unless file

      byte_offsets.map do |offsets|
        batch_load(offsets)
      end
    end

    private

    def batch_load(offsets)
      BatchLoader.for(offsets).batch(key: object_id) do |byte_offsets, loader|
        byte_offsets.uniq
                    .sort
                    .then { |offsets| file.multi_read(offsets) }
                    .map { |data| Gitlab::Json.parse(data) }
                    .zip(byte_offsets)
                    .each { |remediation, offsets| loader.call(offsets, remediation) }
      end
    end
  end
end
