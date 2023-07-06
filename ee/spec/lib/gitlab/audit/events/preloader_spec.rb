# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Audit::Events::Preloader, feature_category: :audit_events do
  let_it_be(:audit_events) do
    [
      create(:audit_event, created_at: 2.days.ago),
      create(:audit_event, created_at: 1.day.ago)
    ]
  end

  let(:audit_events_relation) { AuditEvent.where(id: audit_events.map(&:id)) }

  describe '.preload!' do
    subject { described_class.preload!(audit_events_relation) }

    it 'returns an ActiveRecord::Relation' do
      expect(subject).to be_an(ActiveRecord::Relation)
    end

    it 'preloads associated records' do
      # Expected queries when requesting for AuditEvent with associated records
      #
      # 1. On the audit_events table
      #    SELECT "audit_events".* FROM "audit_events"
      # 2. On the users table for author_name
      #    SELECT "users".* FROM "users" WHERE "users"."id" IN (1, 3)
      # 3. On the users table for entity name
      #    SELECT "users".* FROM "users" WHERE "users"."id" IN (2, 4)
      #
      expect do
        subject.map do |event|
          [event.author_name, event.entity.name]
        end
      end.not_to exceed_query_limit(3)
    end
  end

  describe '#find_each' do
    let(:preloader) { described_class.new(audit_events_relation) }

    it 'yields a list audit events' do
      expect { |b| preloader.find_each(&b) }.to yield_successive_args(*audit_events)
    end

    it 'loads audit events in batches with preloaded associated records' do
      # Expected queries when requesting for AuditEvent with associated records
      #
      # 1. Get the start of created_at value in 1k batch
      #    SELECT "audit_events"."created_at" FROM "audit_events" WHERE "audit_events"."id" IN (1, 2) ORDER BY "audit_events"."created_at" ASC LIMIT 1
      # 2. Get the end of created_at value in 1k batch
      #    SELECT "audit_events"."created_at" FROM "audit_events" WHERE "audit_events"."id" IN (1, 2) AND "audit_events"."created_at" >= '2020-10-15 04:51:06.392709' ORDER BY "audit_events"."created_at" ASC LIMIT 1 OFFSET 1000
      # 3. Get the audit_events in 1k batch
      #    SELECT "audit_events".* FROM "audit_events" WHERE "audit_events"."id" IN (1, 2) AND "audit_events"."created_at" >= '2020-10-15 04:51:06.392709'
      # 4. On the users table for author_name
      #    SELECT "users"."id", "users"."name", "users"."username" FROM "users" WHERE "users"."id" IN (1, 3) ORDER BY "users"."id" ASC LIMIT 1000
      # 5. On the users table for entity name
      #    SELECT "users".* FROM "users" WHERE "users"."id" IN (2, 4) ORDER BY "users"."id" ASC LIMIT 1000
      expect do
        preloader.find_each do |event|
          [event.author_name, event.entity.name]
        end
      end.not_to exceed_query_limit(5)
    end
  end
end
