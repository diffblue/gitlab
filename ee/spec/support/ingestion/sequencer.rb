# frozen_string_literal: true

module Ingestion
  # Sequencer provides a means of generating fake IDs and then
  # asserting that an array contains all of those IDs.
  #
  # For example, if we expect a service to fill a list of objects with
  # IDs, and we expect the unit that we are testing to return a list
  # of those IDs, then we can use the sequencer like this:
  #
  # expect(service).to receive(:execute).with(objects).and_wrap_original do |objects|
  #   objects.each { |object| object.id = sequencer.next }
  # end
  #
  # expect(subject).to match_array(sequencer.range)
  class Sequencer
    def initialize(start: 1)
      @start = start
      @i = start
    end

    def next
      @i.tap { @i += 1 }
    end

    def range
      Range.new(@start, @i - 1).to_a
    end
  end
end
