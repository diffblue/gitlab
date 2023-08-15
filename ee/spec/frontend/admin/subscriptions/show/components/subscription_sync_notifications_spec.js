import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import SubscriptionSyncNotifications, {
  i18n,
} from 'ee/admin/subscriptions/show/components/subscription_sync_notifications.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import * as initialStore from 'ee/admin/subscriptions/show/store';

describe('Subscription Sync Notifications', () => {
  let wrapper;

  const connectivityHelpURL = 'connectivity/help/url';

  const findAllAlerts = () => wrapper.findAllComponents(GlAlert);
  const findFailureAlert = () => wrapper.findByTestId('sync-failure-alert');
  const findSuccessAlert = () => wrapper.findByTestId('sync-success-alert');
  const findLink = () => wrapper.findComponent(GlLink);

  const createStore = ({
    didSyncFail = false,
    didSyncSucceed = false,
    dismissMock = jest.fn(),
  } = {}) => {
    return new Vuex.Store({
      ...initialStore,
      getters: {
        didSyncFail: () => didSyncFail,
        didSyncSucceed: () => didSyncSucceed,
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
      const store = createStore({ didSyncSucceed: true, dismissMock: spy });

      createComponent({
        store,
      });
    });

    it('displays an info alert', () => {
      expect(findSuccessAlert().props('variant')).toBe('info');
    });

    it('displays an alert with a title', () => {
      expect(findSuccessAlert().props('title')).toBe(i18n.MANUAL_SYNC_SUCCESS_TITLE);
    });

    it('displays an alert with a message', () => {
      expect(findSuccessAlert().text()).toBe(i18n.MANUAL_SYNC_SUCCESS_TEXT);
    });

    it('triggers dismissAlert action when dismiss event is emitted', () => {
      findSuccessAlert().vm.$emit('dismiss');

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
        'Subscription details did not synchronize due to a possible connectivity issue with GitLab servers. How do I check connectivity?',
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
