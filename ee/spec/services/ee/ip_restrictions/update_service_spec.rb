# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::IpRestrictions::UpdateService, feature_category: :application_performance do
  subject(:service) { described_class.new(current_user, group, comma_separated_ranges) }

  let(:group) { create(:group) }
  let(:current_user) { create(:user) }
  let(:comma_separated_ranges) { '192.168.0.0/24,10.0.0.0/8' }

  describe '#execute' do
    subject { service.execute }

    context 'for a group that has no ip restriction' do
      context 'with valid IP subnets' do
        it 'builds new ip_restriction records' do
          subject

          expect { group.save! }
            .to(change { group.ip_restrictions.count }.from(0).to(2))
        end

        it 'builds new ip_restriction records with the provided ranges' do
          expect { subject }
            .to(change { group.ip_restrictions.map(&:range) }
            .from([]).to(contain_exactly(*comma_separated_ranges.split(","))))
        end
      end
    end

    context 'for a group that already has ip restriction' do
      let(:ranges) { ['192.168.0.0/24', '10.0.0.0/8'] }

      before do
        ranges.each do |range|
          create(:ip_restriction, group: group, range: range)
        end
      end

      context 'with empty range' do
        let(:comma_separated_ranges) { '' }

        it 'marks all existing ip_restriction records for destruction' do
          expect { subject }
            .to(change { group.ip_restrictions.select(&:marked_for_destruction?).size }.from(0).to(2))
        end
      end

      context 'with valid IP subnets' do
        before do
          subject
        end

        context 'with an entirely new set of ranges' do
          shared_examples 'removes all existing ip_restriction records' do
            it 'marks all the existing ip_restriction records for destruction' do
              records_marked_for_destruction = group.ip_restrictions.select(&:marked_for_destruction?)
              expect(records_marked_for_destruction.map(&:range)).to contain_exactly(*ranges)
            end
          end

          context 'each range in the list is unique' do
            let(:comma_separated_ranges) { '255.255.0.0/16,255.255.128.0/17' }

            it_behaves_like 'removes all existing ip_restriction records'

            it 'builds new ip_restriction records with all of the specified ranges' do
              newly_built_ip_restriction_records = group.ip_restrictions.select { |ip_restriction| ip_restriction.id.nil? }

              expect(newly_built_ip_restriction_records.map(&:range)).to contain_exactly(*comma_separated_ranges.split(","))
            end
          end

          context 'ranges in the list repeats' do
            let(:comma_separated_ranges) { '255.255.0.0/16,255.255.0.0/16,255.255.128.0/17' }

            it_behaves_like 'removes all existing ip_restriction records'

            it 'builds new ip_restriction records with only the unique ranges in the specified ranges' do
              newly_built_ip_restriction_records = group.ip_restrictions.select { |ip_restriction| ip_restriction.id.nil? }

              expect(newly_built_ip_restriction_records.map(&:range)).to contain_exactly(*comma_separated_ranges.split(",").uniq)
            end
          end
        end

        context 'replacing one of the existing range with another' do
          # replacing '10.0.0.0/8' with '255.255.128.0/17' and retaining '192.168.0.0/24'
          let(:comma_separated_ranges) { '192.168.0.0/24,255.255.128.0/17' }

          it 'marks the ip_restriction record of the replaced range for destruction' do
            ip_restriction_record_of_replaced_range = group.ip_restrictions.find { |ip_restriction| ip_restriction.range == '10.0.0.0/8' }

            expect(ip_restriction_record_of_replaced_range.marked_for_destruction?).to be_truthy
          end

          it 'retains the ip_restriction record of the other existing range' do
            ip_restriction_record_of_other_existing_range = group.ip_restrictions.find { |ip_restriction| ip_restriction.range == '192.168.0.0/24' }

            expect(ip_restriction_record_of_other_existing_range.marked_for_destruction?).to be_falsey
          end

          it 'builds a new ip_restriction record with the newly specified range' do
            newly_built_ip_restriction_records = group.ip_restrictions.select { |ip_restriction| ip_restriction.id.nil? }

            expect(newly_built_ip_restriction_records.size).to eq(1)
            expect(newly_built_ip_restriction_records.map(&:range)).to include('255.255.128.0/17')
          end
        end
      end
    end
  end

  describe '#log_audit_event' do
    before do
      stub_licensed_features(extended_audit_events: true)
    end

    context 'when new ranges are different from old ranges' do
      it "logs ip_restrictions_changed event" do
        subject.execute

        expect(Gitlab::Audit::Auditor).to receive(:audit).with(
          name: 'ip_restrictions_changed',
          message: "Group IP restrictions updated from '' to '#{comma_separated_ranges}'",
          target: group,
          scope: group,
          author: current_user
        ).and_call_original

        subject.log_audit_event
      end

      context "when license doesn't allow auditing" do
        before do
          stub_licensed_features(extended_audit_events: false)
        end

        it "doesn't log any events" do
          subject.execute

          expect(Gitlab::Audit::Auditor).not_to receive(:audit)

          subject.log_audit_event
        end
      end
    end

    context 'when new ranges are the same as old ranges' do
      before do
        comma_separated_ranges.split(',').reverse_each do |range|
          create(:ip_restriction, group: group, range: range)
        end
      end

      it "doesn't log any events" do
        subject.execute

        expect(Gitlab::Audit::Auditor).not_to receive(:audit)

        subject.log_audit_event
      end
    end

    context 'when log is called without prior execute' do
      it 'raises an error' do
        expect { subject.log_audit_event }
          .to raise_error("Nothing to log, the service must be executed first.")
      end
    end
  end
end
