# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Unicode do
  describe described_class::REGEXP do
    using RSpec::Parameterized::TableSyntax

    where(:string, :match) do
      "\u2066"       | true # left-to-right isolate
      "\u2067"       | true # right-to-left isolate
      "\u2068"       | true # first strong isolate
      "\u2069"       | true # pop directional isolate
      "\u202a"       | true # left-to-right embedding
      "\u202b"       | true # right-to-left embedding
      "\u202c"       | true # pop directional formatting
      "\u202d"       | true # left-to-right override
      "\u202e"       | true # right-to-left override
      "\u2066foobar" | true
      ""             | false
      "foo"          | false
      "\u2713"       | false # checkmark
      "\u037E"       | true # greek question mark
      ";"            | false # normal semicolon
      "1234567890"   | false
      "<>{}[]()-^=+/\,.;:!?#$%&'_|\"" | false
      ("a".."z").to_a.join            | false
    end

    with_them do
      let(:utf8_string) { string.encode("utf-8") }

      it "matches only the unicode characters" do
        expect(utf8_string.match?(Regexp.union(subject.values))).to eq(match)
      end
    end
  end
end
