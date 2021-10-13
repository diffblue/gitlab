import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SubscriptionSyncNotifications, {
  INFO_ALERT_DISMISSED_EVENT,
} from 'ee/admin/subscriptions/show/components/subscription_sync_notifications.vue';
import {
  connectivityIssue,
  manualSyncPendingText,
  manualSyncPendingTitle,
  subscriptionSyncStatus,
} from 'ee/admin/subscriptions/show/constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('Subscription Sync Notifications', () => {
  let wrapper;

  const connectivityHelpURL = 'connectivity/help/url';

  const finAllAlerts = () => wrapper.findAllComponents(GlAlert);
  const findFailureAlert = () => wrapper.findByTestId('sync-failure-alert');
  const findInfoAlert = () => wrapper.findByTestId('sync-info-alert');
  const findLink = () => wrapper.findComponent(GlLink);

  const createComponent = ({ props, stubs } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(SubscriptionSyncNotifications, {
        propsData: {
          syncStatus: '',
          ...props,
        },
        provide: { connectivityHelpURL },
        stubs,
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('idle state', () => {
    it('displays no alert', () => {
      createComponent();

      expect(finAllAlerts()).toHaveLength(0);
    });
  });

  describe('sync info notification', () => {
    beforeEach(() => {
      createComponent({
        props: { syncStatus: subscriptionSyncStatus.SYNC_PENDING },
      });
    });

    it('displays an info alert', () => {
      expect(findInfoAlert().props('variant')).toBe('info');
    });

    it('displays an alert with a title', () => {
      expect(findInfoAlert().props('title')).toBe(manualSyncPendingTitle);
    });

    it('displays an alert with a message', () => {
      expect(findInfoAlert().text()).toBe(manualSyncPendingText);
    });

    it('emits an event when dismissed', () => {
      findInfoAlert().vm.$emit('dismiss');

      expect(wrapper.emitted(INFO_ALERT_DISMISSED_EVENT)).toHaveLength(1);
    });
  });

  describe('sync failure notification', () => {
    beforeEach(() => {
      createComponent({
        props: { syncStatus: subscriptionSyncStatus.SYNC_FAILURE },
        stubs: { GlSprintf },
      });
    });

    it('displays an alert with a failure title', () => {
      expect(findFailureAlert().props('title')).toBe(connectivityIssue);
    });

    it('displays an alert with a failure message', () => {
      expect(findFailureAlert().text()).toBe(
        'You can no longer sync your subscription details with GitLab. Get help for the most common connectivity issues by troubleshooting the activation code.',
      );
    });

    it('displays a link', () => {
      expect(findLink().attributes('href')).toBe(connectivityHelpURL);
    });
  });
});
