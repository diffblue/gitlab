# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TrialRegistrations::ReassurancesHelper do
  describe '#reassurance_orgs' do
    subject(:reassurance_orgs) { helper.reassurance_orgs }

    it 'returns an array of ReassuranceOrg objects' do
      expect(reassurance_orgs).to be_an(Array)
      expect(reassurance_orgs).to all(be_an_instance_of(Struct::ReassuranceOrg))
    end
  end

  describe 'Struct::ReassuranceOrg' do
    using RSpec::Parameterized::TableSyntax

    let(:given_opacity_level) { nil }

    subject(:org) { Struct::ReassuranceOrg.new(name: 'Foo Bar Baz', opacity_level: given_opacity_level) }

    describe '#name' do
      it "returns the organization's name" do
        expect(org.name).to eq('Foo Bar Baz')
      end
    end

    describe '#opacity_level' do
      where(:given_opacity_level, :expected_opacity_level) do
        nil | 5
        5   | 5
        6   | 6
        7   | 7
      end

      with_them do
        it 'returns the given value or the default value' do
          expect(org.opacity_level).to eq(expected_opacity_level)
        end
      end
    end

    describe '#opacity_css_class' do
      where(:given_opacity_level, :expected_opacity_css_class) do
        nil | 'gl-opacity-5'
        5   | 'gl-opacity-5'
        6   | 'gl-opacity-6'
        7   | 'gl-opacity-7'
      end

      with_them do
        it 'returns a gitlab-ui utility CSS class for the opacity_level' do
          expect(org.opacity_css_class).to eq(expected_opacity_css_class)
        end
      end
    end

    describe '#image_alt_text' do
      it "returns alt text for the organization's logo image" do
        expect(org.image_alt_text).to eq('Foo Bar Baz logo')
      end
    end

    describe '#logo_image_path' do
      it "returns the path to the organization's logo image" do
        expect(org.logo_image_path).to eq('marketing/logos/logo_foo-bar-baz.svg')
      end
    end
  end
end
