import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { TRIAL_ACTIVE_UNLIMITED_USERS_ALERT_TITLE } from 'ee/invite_members/constants';
import EEActiveTrialNotification from 'ee/invite_members/components/active_trial_notification.vue';

const ALERT_BODY =
  "During your trial, you can invite as many members to name as you like. When the trial ends, you'll have a maximum of 5 members on the Free tier. To get more members, upgrade to a paid plan.";

describe('EEActiveTrialNotification', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLink = () => wrapper.findComponent(GlLink);

  const createComponent = (activeTrialDataset) => {
    wrapper = shallowMountExtended(EEActiveTrialNotification, {
      propsData: { activeTrialDataset },
      provide: { name: 'name' },
      stubs: { GlSprintf },
    });
  };

  it('shows the alert when a trial is active', () => {
    createComponent({ freeUsersLimit: '5', purchasePath: 'purchasePath' });

    const alert = findAlert();

    expect(alert.attributes('title')).toBe(TRIAL_ACTIVE_UNLIMITED_USERS_ALERT_TITLE);
    expect(alert.text()).toBe(ALERT_BODY);

    expect(findLink().attributes('href')).toBe('purchasePath');
  });

  it('does not show the alert when a trial is not active', () => {
    createComponent({});

    expect(findAlert().exists()).toBe(false);
  });
});
