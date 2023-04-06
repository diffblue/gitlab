# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CodeOwners::Section, feature_category: :source_code_management do
  using RSpec::Parameterized::TableSyntax

  let(:sectional_data) { {} }

  describe '.parse' do
    subject(:section) { described_class.parse(line, sectional_data) }

    context 'when line is not a section header' do
      let(:line) { 'foo' }

      it { is_expected.to be_nil }
    end

    context 'when line is a section header' do
      where(:line, :name, :optional, :approvals, :default_owners, :sectional_data) do
        '[Doc]'               | 'Doc' | false | 0 | ''          | {}
        '[Doc]'               | 'doc' | false | 0 | ''          | { 'doc' => {} }
        '[Doc]'               | 'Doc' | false | 0 | ''          | { 'foo' => {} }
        '^[Doc]'              | 'Doc' | true  | 0 | ''          | {}
        '[Doc][1]'            | 'Doc' | false | 1 | ''          | {}
        '^[Doc][1]'           | 'Doc' | true  | 1 | ''          | {}
        '^[Doc][1] @doc'      | 'Doc' | true  | 1 | '@doc'      | {}
        '^[Doc][1] @doc @dev' | 'Doc' | true  | 1 | '@doc @dev' | {}
        '^[Doc][1] @gl/doc-1' | 'Doc' | true  | 1 | '@gl/doc-1' | {}
        '[Doc][1] @doc'       | 'Doc' | false | 1 | '@doc'      | {}
        '[Doc] @doc'          | 'Doc' | false | 0 | '@doc'      | {}
        '^[Doc] @doc'         | 'Doc' | true  | 0 | '@doc'      | {}
        '[Doc] @doc @rrr.dev @dev' | 'Doc' | false | 0 | '@doc @rrr.dev @dev' | {}
        '^[Doc] @doc @rrr.dev @dev' | 'Doc' | true | 0 | '@doc @rrr.dev @dev' | {}
        '[Doc][2] @doc @rrr.dev @dev' | 'Doc' | false | 2 | '@doc @rrr.dev @dev' | {}
      end

      with_them do
        it 'parses all section properties', :aggregate_failures do
          expect(section).to be_present
          expect(section.name).to eq(name)
          expect(section.optional).to eq(optional)
          expect(section.approvals).to eq(approvals)
          expect(section.default_owners).to eq(default_owners)
        end
      end
    end
  end
end
