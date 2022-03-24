# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../db/seeds/awesome_co/awesome_co'

module AwesomeCo
  RSpec.describe AwesomeCo do
    let(:owner) { create(:user) }

    subject(:seeder) { described_class.new(owner) }

    describe 'FactoryBot methods' do
      it 'responds to :create' do
        expect(seeder).to respond_to(:create)
      end

      it 'responds to :create_list' do
        expect(seeder).to respond_to(:create_list)
      end
    end

    describe '#seed' do
      before(:all) do
        # seed once for all tests
        @namespace = described_class.new(create(:user)).seed
      end

      describe 'Logistics group' do
        let(:logistics_group) { @namespace.children.find_by_name('Logistics') }

        it 'creates a Squad C project' do
          expect(logistics_group.projects.find_by_name('Squad C')).not_to be_nil
        end
      end

      describe 'Alliances group' do
        let(:alliances_group) { @namespace.children.find_by_name('Alliances') }

        it 'creates a Squad E project' do
          expect(alliances_group.projects.find_by_name('Squad E')).not_to be_nil
        end

        it 'creates a Squad F project' do
          expect(alliances_group.projects.find_by_name('Squad F')).not_to be_nil
        end
      end

      describe 'Consumer Products group' do
        let(:consumer_products_group) { @namespace.children.find_by_name('Consumer Products') }

        it 'creates a Web App project' do
          expect(consumer_products_group.projects.find_by_name('Web App')).not_to be_nil
        end

        it 'creates a Mobile App project' do
          expect(consumer_products_group.projects.find_by_name('Mobile App')).not_to be_nil
        end
      end

      describe 'Services group' do
        let(:services_group) { @namespace.children.find_by_name('Services') }

        it 'creates a Labels project' do
          expect(services_group.projects.find_by_name('Labels')).not_to be_nil
        end

        it 'creates an API project' do
          expect(services_group.projects.find_by_name('API')).not_to be_nil
        end

        it 'creates a Customer Portal project' do
          expect(services_group.projects.find_by_name('Customer Portal')).not_to be_nil
        end
      end

      it 'creates an Ideas project' do
        expect(@namespace.projects.find_by_name('Ideas')).not_to be_nil
      end

      it 'creates an Ops project' do
        expect(@namespace.projects.find_by_name('Ops')).not_to be_nil
      end
    end

    describe '.seed' do
      it 'seeds and returns a group' do
        expect(::AwesomeCo.seed(owner)).to be_a(Group)
      end
    end
  end
end
