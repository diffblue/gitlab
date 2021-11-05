# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::AttributesPermitter do
  describe '#permitted_attributes_defined?' do
    using RSpec::Parameterized::TableSyntax

    let(:attributes_permitter) { described_class.new }

    where(:relation_name, :permitted_attributes_defined) do
      :push_rule               | true
      :issuable_sla            | false
      :unprotect_access_levels | true
      :deploy_access_levels    | true
      :protected_environments  | true
      :security_setting        | true
    end

    with_them do
      it { expect(attributes_permitter.permitted_attributes_defined?(relation_name)).to eq(permitted_attributes_defined) }
    end
  end

  describe 'included_attributes for Project' do
    let(:prohibited_attributes) { %i[remote_url my_attributes my_ids token my_id test] }

    subject { described_class.new }

    additional_attributes = { user: %w[id] }

    Gitlab::ImportExport::Config.new.to_h[:included_attributes].each do |relation_sym, permitted_attributes|
      context "for #{relation_sym}" do
        it_behaves_like 'a permitted attribute', relation_sym, permitted_attributes, additional_attributes[relation_sym]
      end
    end
  end
end
