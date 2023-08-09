# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Type::CvssVector, feature_category: :vulnerability_management do
  subject(:type) { described_class.new }

  describe '#serialize' do
    it 'serializes nil to nil' do
      expect(type.serialize(nil)).to be_nil
    end

    it 'serializes strings as-is' do
      expect(type.serialize('CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:N')).to eq(
        'CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:N')
    end

    [
      'CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:N',
      'CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:N',
      'AV:L/AC:H/Au:M/C:N/I:N/A:N'
    ].each do |vector|
      it "serializes CvssSuite::Cvss for #{vector}" do
        expect(type.serialize(::CvssSuite.new(vector))).to eq(vector)
      end
    end
  end

  describe '#serializable?' do
    using RSpec::Parameterized::TableSyntax

    where(:input, :expected) do
      'CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:N'                | true
      CvssSuite.new('CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:N') | true
      nil                                                           | true
      1                                                             | false
      true                                                          | false
      'foo'                                                         | false
      'CVSS:3.1/AV:INVALID/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:N'          | false
    end

    with_them do
      it 'returns expected value' do
        expect(type.serializable?(input)).to eq(expected)
      end
    end
  end

  describe '#cast' do
    it 'casts nil to nil' do
      expect(type.cast(nil)).to be_nil
    end

    it 'casts strings to CvssSuite::Cvss' do
      expect(type.cast('CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:N')).to be_a(::CvssSuite::Cvss31)
      expect(type.cast('CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:N')).to be_a(::CvssSuite::Cvss3)
      expect(type.cast('AV:L/AC:H/Au:M/C:N/I:N/A:N')).to be_a(::CvssSuite::Cvss2)
    end
  end
end
