# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveUserCountThresholdWorker, feature_category: :sm_provisioning do
  using RSpec::Parameterized::TableSyntax

  subject { described_class.new }

  let(:license) { build(:license) }

  describe '#perform' do
    where(:trial?, :threshold_reached?, :should_send_reminder?) do
      false | false | false
      false | true  | true
      true  | false | false
      true  | true  | false
    end

    with_them do
      before do
        allow(license).to receive(:trial?).and_return(trial?)
        allow(license).to receive(:active_user_count_threshold_reached?).and_return(threshold_reached?)
        allow(License).to receive(:current).and_return(license)
      end

      it do
        if should_send_reminder?
          expect(LicenseMailer).to receive(:approaching_active_user_count_limit)
        else
          expect(LicenseMailer).not_to receive(:approaching_active_user_count_limit)
        end

        subject.perform
      end
    end

    context 'recipients' do
      let_it_be(:admins) { create_list(:admin, 3) }

      before do
        allow(license).to receive(:trial?).and_return(false)
        allow(license).to receive(:active_user_count_threshold_reached?).and_return(true)
        allow(License).to receive(:current).and_return(license)
      end

      it 'sends reminder to admins only' do
        admins_emails = admins.pluck(:email)

        expect(LicenseMailer).to receive(:approaching_active_user_count_limit).with(array_including(*admins_emails))

        subject.perform
      end

      it 'adds a licensee email to the recipients list' do
        allow(license).to receive(:licensee).and_return({ 'Email' => admins.first.email })
        licensee_email = license.licensee['Email']

        expect(LicenseMailer).to receive(:approaching_active_user_count_limit).with(array_including([licensee_email]))

        subject.perform
      end

      it 'sends reminder to unique emails' do
        admins_emails = admins.pluck(:email)
        allow(license.licensee).to receive('Email').and_return(admins.first.email)

        expect(LicenseMailer).to receive(:approaching_active_user_count_limit).with(array_including(*admins_emails))

        subject.perform
      end

      it 'sends reminder to active admins only' do
        admins.first.deactivate!

        active_admins_emails = admins.drop(1).pluck(:email)

        expect(LicenseMailer).to receive(:approaching_active_user_count_limit).with(array_including(*active_admins_emails))

        subject.perform
      end
    end

    context 'when there is no license' do
      it 'does not send a reminder' do
        expect(LicenseMailer).not_to receive(:approaching_active_user_count_limit)

        subject.perform
      end
    end
  end
end
