import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import SubscriptionSyncNotifications, {
  i18n,
} from 'ee/admin/subscriptions/show/components/subscription_sync_notifications.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import * as initialStore from 'ee/admin/subscriptions/show/store/';

describe('Subscription Sync Notifications', () => {
  let wrapper;

  const connectivityHelpURL = 'connectivity/help/url';

  const findAllAlerts = () => wrapper.findAllComponents(GlAlert);
  const findFailureAlert = () => wrapper.findByTestId('sync-failure-alert');
  const findInfoAlert = () => wrapper.findByTestId('sync-info-alert');
  const findLink = () => wrapper.findComponent(GlLink);

  const createStore = ({
    didSyncFail = false,
    isSyncPending = false,
    dismissMock = jest.fn(),
  } = {}) => {
    return new Vuex.Store({
      ...initialStore,
      getters: {
        didSyncFail: () => didSyncFail,
        isSyncPending: () => isSyncPending,
      },
      actions: {
        dismissAlert: dismissMock,
      },
    });
  };

  const createComponent = ({ stubs, store = createStore() } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(SubscriptionSyncNotifications, {
        store,
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

      expect(findAllAlerts()).toHaveLength(0);
    });
  });

  describe('sync info notification', () => {
    let spy;

    beforeEach(() => {
      spy = jest.fn();
      const store = createStore({ isSyncPending: true, dismissMock: spy });

      createComponent({
        store,
      });
    });

    it('displays an info alert', () => {
      expect(findInfoAlert().props('variant')).toBe('info');
    });

    it('displays an alert with a title', () => {
      expect(findInfoAlert().props('title')).toBe(i18n.MANUAL_SYNC_PENDING_TITLE);
    });

    it('displays an alert with a message', () => {
      expect(findInfoAlert().text()).toBe(i18n.MANUAL_SYNC_PENDING_TEXT);
    });

    it('triggers dismissAlert action when dismiss event is emitted', () => {
      findInfoAlert().vm.$emit('dismiss');

      expect(spy).toHaveBeenCalled();
    });
  });

  describe('sync failure notification', () => {
    let spy;

    beforeEach(() => {
      spy = jest.fn();

      createComponent({
        store: createStore({ didSyncFail: true, dismissMock: spy }),
        stubs: { GlSprintf },
      });
    });

    it('displays an alert with a failure title', () => {
      expect(findFailureAlert().props('title')).toBe(i18n.CONNECTIVITY_ERROR_TITLE);
    });

    it('displays an alert with a failure message', () => {
      expect(findFailureAlert().text()).toBe(
        'You can no longer sync your subscription details with GitLab. Get help for the most common connectivity issues by troubleshooting the activation code.',
      );
    });

    it('does not trigger dismissAlert action when dismiss event is emitted', () => {
      findFailureAlert().vm.$emit('dismiss');

      expect(spy).not.toHaveBeenCalled();
    });

    it('displays a link', () => {
      expect(findLink().attributes('href')).toBe(connectivityHelpURL);
    });
  });
});
