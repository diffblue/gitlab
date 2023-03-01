# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AllowedEmailDomain, feature_category: :team_planning do
  describe 'relations' do
    it { is_expected.to belong_to(:group) }
  end

  describe '.domain_names' do
    subject { described_class.domain_names }

    let(:domains) { ['gitlab.com', 'acme.com'] }

    before do
      domains.each do |domain|
        create(:allowed_email_domain, domain: domain)
      end
    end

    it 'returns the array of domain names' do
      expect(subject).to match_array(domains)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:domain) }
    it { is_expected.to validate_presence_of(:group_id) }

    describe '#valid domain' do
      subject { described_class.new(group: create(:group), domain: domain) }

      let_it_be(:group) { create(:group) }

      context 'valid domain' do
        let(:valid_domains) { ['gitlab.com', 'gitlab.co.uk', 'GITLAB.COM'] }

        it 'succeeds' do
          valid_domains.each do |domain|
            overridden_subject = described_class.new(group: group, domain: domain)
            expect(overridden_subject.valid?).to be_truthy
          end
        end
      end

      context 'invalid domain' do
        let(:invalid_domains) do
          ['gitlab', 'git?lab.com', 'gitlab.com!', 'gitlab.@com', 'gitla>b.com', 'gitl<a>b@.c?om!']
        end

        it 'fails' do
          invalid_domains.each do |domain|
            overridden_subject = described_class.new(group: group, domain: domain)
            expect(overridden_subject.valid?).to be_falsey
            expect(overridden_subject.errors[:domain]).to include('The domain you entered is misformatted.')
          end
        end
      end

      context 'domain from excluded list' do
        let(:domain) { 'hotmail.co.uk' }

        it 'fails' do
          expect(subject.valid?).to be_falsey
          expect(subject.errors[:domain]).to include('The domain you entered is not allowed.')
        end
      end
    end

    describe '#allow_root_group_only' do
      subject { described_class.new(group: group, domain: 'gitlab.com' ) }

      context 'top-level group' do
        let(:group) { create(:group) }

        it 'succeeds' do
          expect(subject.valid?).to be_truthy
        end
      end

      context 'subgroup' do
        let(:group) { create(:group, :nested) }

        it 'fails' do
          expect(subject.valid?).to be_falsey
          expect(subject.errors[:base]).to include('Allowed email domain restriction only permitted for top-level groups')
        end
      end
    end
  end

  describe '#email_matches_domain?' do
    subject { described_class.new(group: create(:group), domain: 'gitlab.com') }

    context 'with matching domain' do
      it 'returns true' do
        expect(subject.email_matches_domain?('test@gitlab.com')).to eq(true)
      end
    end

    context 'with not matching domain' do
      it 'returns false' do
        expect(subject.email_matches_domain?('test@gitlab.com.uk')).to eq(false)
      end
    end
  end

  describe '#email_domain' do
    subject { described_class.new(group: create(:group), domain: 'gitlab.com') }

    it 'returns formatted domain' do
      expect(subject.email_domain).to eq('@gitlab.com')
    end
  end
end
