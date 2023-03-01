# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::AllowedEmailDomains::UpdateService, feature_category: :team_planning do
  let(:group) { create(:group) }
  let(:user) { create(:user) }

  subject { described_class.new(user, group, comma_separated_domains_list).execute }

  describe '#execute' do
    context 'as a normal user' do
      context 'for a group that has no email domain restriction' do
        context 'with valid domains' do
          let(:comma_separated_domains_list) { 'gitlab.com,acme.com' }

          it 'does not build new allowed_email_domain records' do
            subject

            expect { group.save! }
              .not_to(change { group.allowed_email_domains.count }.from(0))
          end

          it 'registers an error' do
            subject

            expect(group.errors[:allowed_email_domains]).to include('cannot be changed by you')
          end
        end
      end
    end

    context 'as a group owner' do
      before do
        group.add_owner(user)
      end

      context 'for a group that has no email domain restriction' do
        context 'with valid domains' do
          let(:comma_separated_domains_list) { 'gitlab.com,acme.com' }

          it 'builds new allowed_email_domain records' do
            subject

            expect { group.save! }
              .to(change { group.allowed_email_domains.count }.from(0).to(2))
          end

          it 'builds new allowed_email_domain records with the provided domains' do
            subject

            expect(group.allowed_email_domains.map(&:domain)).to match_array(comma_separated_domains_list.split(","))
          end
        end
      end

      context 'for a group that already has email domain restriction' do
        let(:domains) { ['gitlab.com', 'acme.com'] }

        before do
          domains.each do |domain|
            create(:allowed_email_domain, group: group, domain: domain)
          end
        end

        context 'with empty domain' do
          let(:comma_separated_domains_list) { '' }

          it 'marks all existing allowed_email_domain records for destruction' do
            expect { subject }
              .to(change { group.allowed_email_domains.select(&:marked_for_destruction?).size }.from(0).to(2))
          end
        end

        context 'with valid domains' do
          before do
            subject
          end

          context 'with an entirely new set of domains' do
            shared_examples 'removes all existing allowed_email_domain records' do
              it 'marks all the existing allowed_email_domain records for destruction' do
                records_marked_for_destruction = group.allowed_email_domains.select(&:marked_for_destruction?)
                expect(records_marked_for_destruction.map(&:domain)).to match_array(domains)
              end
            end

            context 'each domain in the list is unique' do
              let(:comma_separated_domains_list) { 'hey.com,google.com,twitter.com' }

              it_behaves_like 'removes all existing allowed_email_domain records'

              it 'builds new allowed_email_domain records with all of the specified domains' do
                newly_built_allowed_email_domain_records = group.allowed_email_domains.select { |allowed_email_domain| allowed_email_domain.id.nil? }

                expect(newly_built_allowed_email_domain_records.map(&:domain)).to match_array(comma_separated_domains_list.split(",").map(&:strip))
              end

              context 'list has space around the names of domains' do
                let(:comma_separated_domains_list) { 'hey.com, google.com,  twitter.com' }

                it_behaves_like 'removes all existing allowed_email_domain records'

                it 'builds new allowed_email_domain records with all of the specified domains without spaces around them' do
                  newly_built_allowed_email_domain_records = group.allowed_email_domains.select { |allowed_email_domain| allowed_email_domain.id.nil? }

                  expect(newly_built_allowed_email_domain_records.map(&:domain)).to match_array(comma_separated_domains_list.split(",").map(&:strip))
                end
              end
            end

            context 'domains in the list repeats' do
              let(:comma_separated_domains_list) { 'hey.com,google.com,hey.com' }

              it_behaves_like 'removes all existing allowed_email_domain records'

              it 'builds new allowed_email_domain records with only the unique domains among the specified domains' do
                newly_built_allowed_email_domain_records = group.allowed_email_domains.select { |allowed_email_domain| allowed_email_domain.id.nil? }

                expect(newly_built_allowed_email_domain_records.map(&:domain)).to match_array(comma_separated_domains_list.split(",").map(&:strip).uniq)
              end
            end
          end

          context 'replacing one of the existing domains with another' do
            # replacing 'acme.com' with 'hey.com' and retaining 'gitlab.com'

            let(:comma_separated_domains_list) { 'gitlab.com,hey.com' }

            it 'marks the allowed_email_domain record of the replaced domain for destruction' do
              allowed_email_domain_record_of_replaced_domain = group.allowed_email_domains.find { |allowed_email_domain| allowed_email_domain.domain == 'acme.com' }

              expect(allowed_email_domain_record_of_replaced_domain.marked_for_destruction?).to be_truthy
            end

            it 'retains the allowed_email_domain record of the other existing domain' do
              allowed_email_domain_record_of_other_existing_domain = group.allowed_email_domains.find { |allowed_email_domain| allowed_email_domain.domain == 'gitlab.com' }

              expect(allowed_email_domain_record_of_other_existing_domain.marked_for_destruction?).to be_falsey
            end

            it 'builds a new allowed_email_domain record with the newly specified domain' do
              newly_built_allowed_email_domain_records = group.allowed_email_domains.select { |allowed_email_domain| allowed_email_domain.id.nil? }

              expect(newly_built_allowed_email_domain_records.size).to eq(1)
              expect(newly_built_allowed_email_domain_records.map(&:domain)).to match_array(['hey.com'])
            end
          end
        end
      end
    end
  end
end
