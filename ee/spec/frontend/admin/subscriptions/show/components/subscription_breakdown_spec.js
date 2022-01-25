import { GlCard } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import SubscriptionActivationBanner, {
  ACTIVATE_SUBSCRIPTION_EVENT,
} from 'ee/admin/subscriptions/show/components/subscription_activation_banner.vue';
import SubscriptionActivationModal from 'ee/admin/subscriptions/show/components/subscription_activation_modal.vue';
import SubscriptionBreakdown, {
  licensedToFields,
  modalId,
  subscriptionDetailsFields,
} from 'ee/admin/subscriptions/show/components/subscription_breakdown.vue';
import SubscriptionDetailsCard from 'ee/admin/subscriptions/show/components/subscription_details_card.vue';
import SubscriptionDetailsHistory from 'ee/admin/subscriptions/show/components/subscription_details_history.vue';
import SubscriptionDetailsUserInfo from 'ee/admin/subscriptions/show/components/subscription_details_user_info.vue';
import SubscriptionSyncNotifications, {
  INFO_ALERT_DISMISSED_EVENT,
} from 'ee/admin/subscriptions/show/components/subscription_sync_notifications.vue';
import {
  licensedToHeaderText,
  subscriptionSyncStatus,
  subscriptionDetailsHeaderText,
  subscriptionTypes,
} from 'ee/admin/subscriptions/show/constants';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { license, subscriptionHistory } from '../mock_data';

describe('Subscription Breakdown', () => {
  let axiosMock;
  let wrapper;
  let glModalDirective;
  let userCalloutDismissSpy;

  const [, licenseFile] = subscriptionHistory;
  const congratulationSvgPath = '/path/to/svg';
  const connectivityHelpURL = 'connectivity/help/url';
  const customersPortalUrl = 'customers.dot';
  const licenseRemovePath = '/license/remove/';
  const subscriptionActivationBannerCalloutName = 'banner_callout_name';
  const subscriptionSyncPath = '/sync/path/';

  const findDetailsCards = () => wrapper.findAllComponents(SubscriptionDetailsCard);
  const findDetailsCardFooter = () => wrapper.find('.gl-card-footer');
  const findDetailsHistory = () => wrapper.findComponent(SubscriptionDetailsHistory);
  const findDetailsUserInfo = () => wrapper.findComponent(SubscriptionDetailsUserInfo);
  const findLicenseUploadAction = () => wrapper.findByTestId('license-upload-action');
  const findLicenseRemoveAction = () => wrapper.findByTestId('license-remove-action');
  const findActivateSubscriptionAction = () =>
    wrapper.findByTestId('subscription-activate-subscription-action');
  const findSubscriptionMangeAction = () => wrapper.findByTestId('subscription-manage-action');
  const findSubscriptionSyncAction = () => wrapper.findByTestId('subscription-sync-action');
  const findSubscriptionActivationBanner = () =>
    wrapper.findComponent(SubscriptionActivationBanner);
  const findSubscriptionActivationModal = () => wrapper.findComponent(SubscriptionActivationModal);
  const findSubscriptionSyncNotifications = () =>
    wrapper.findComponent(SubscriptionSyncNotifications);

  const createComponent = ({
    props = {},
    provide = {},
    stubs = {},
    mountMethod = shallowMount,
    shouldShowCallout = true,
  } = {}) => {
    glModalDirective = jest.fn();
    userCalloutDismissSpy = jest.fn();
    wrapper = extendedWrapper(
      mountMethod(SubscriptionBreakdown, {
        directives: {
          glModal: {
            bind(_, { value }) {
              glModalDirective(value);
            },
          },
        },
        provide: {
          congratulationSvgPath,
          connectivityHelpURL,
          customersPortalUrl,
          licenseRemovePath,
          subscriptionActivationBannerCalloutName,
          subscriptionSyncPath,
          ...provide,
        },
        propsData: {
          subscription: license.ULTIMATE,
          subscriptionList: subscriptionHistory,
          ...props,
        },
        stubs: {
          UserCalloutDismisser: makeMockUserCalloutDismisser({
            dismiss: userCalloutDismissSpy,
            shouldShowCallout,
          }),
          ...stubs,
        },
      }),
    );
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
    wrapper.destroy();
  });

  describe('with subscription data', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows 2 details card', () => {
      expect(findDetailsCards()).toHaveLength(2);
    });

    it('provides the correct props to the cards', () => {
      const props = findDetailsCards().wrappers.map((w) => w.props());

      expect(props).toEqual(
        expect.arrayContaining([
          {
            detailsFields: subscriptionDetailsFields,
            headerText: subscriptionDetailsHeaderText,
            subscription: license.ULTIMATE,
            syncDidFail: false,
          },
          {
            detailsFields: licensedToFields,
            headerText: licensedToHeaderText,
            subscription: license.ULTIMATE,
            syncDidFail: false,
          },
        ]),
      );
    });

    it('shows the user info', () => {
      expect(findDetailsUserInfo().exists()).toBe(true);
    });

    it('provides the correct props to the user info component', () => {
      expect(findDetailsUserInfo().props('subscription')).toBe(license.ULTIMATE);
    });

    it('does not show notifications', () => {
      expect(findSubscriptionSyncNotifications().exists()).toBe(false);
    });

    it('shows the subscription details footer', () => {
      createComponent({ stubs: { GlCard, SubscriptionDetailsCard } });

      expect(findDetailsCardFooter().exists()).toBe(true);
    });

    it('presents a subscription activation modal', () => {
      expect(findSubscriptionActivationModal().props()).toMatchObject({
        modalId,
        visible: false,
      });
    });

    it('updates visible of subscription activation modal when change emitted', async () => {
      findSubscriptionActivationModal().vm.$emit('change', true);

      await nextTick();

      expect(findSubscriptionActivationModal().props('visible')).toBe(true);
    });

    it('does not present a subscription activation banner', () => {
      expect(findSubscriptionActivationBanner().exists()).toBe(false);
    });

    describe('footer buttons', () => {
      it.each`
        url                     | type                              | shouldShow
        ${subscriptionSyncPath} | ${subscriptionTypes.CLOUD}        | ${true}
        ${subscriptionSyncPath} | ${subscriptionTypes.LICENSE_FILE} | ${false}
        ${''}                   | ${subscriptionTypes.CLOUD}        | ${false}
        ${''}                   | ${subscriptionTypes.LICENSE_FILE} | ${false}
        ${undefined}            | ${subscriptionTypes.CLOUD}        | ${false}
        ${undefined}            | ${subscriptionTypes.LICENSE_FILE} | ${false}
      `(
        'with url is $url and type is $type the sync button is shown: $shouldShow',
        ({ url, type, shouldShow }) => {
          const provide = {
            connectivityHelpURL: '',
            customersPortalUrl: '',
            licenseRemovePath: '',
            subscriptionSyncPath: url,
          };
          const props = { subscription: { ...license.ULTIMATE, type } };
          const stubs = { GlCard, SubscriptionDetailsCard };
          createComponent({ props, provide, stubs });

          expect(findSubscriptionSyncAction().exists()).toBe(shouldShow);
        },
      );

      it('does not show upload legacy license button', () => {
        createComponent();

        expect(findLicenseUploadAction().exists()).toBe(false);
      });

      it.each`
        url                   | shouldShow
        ${customersPortalUrl} | ${true}
        ${''}                 | ${false}
        ${undefined}          | ${false}
      `('with url is $url the manage button is shown: $shouldShow', ({ url, shouldShow }) => {
        const provide = {
          connectivityHelpURL: '',
          licenseRemovePath: '',
          subscriptionSyncPath: '',
          customersPortalUrl: url,
        };
        const stubs = { GlCard, SubscriptionDetailsCard };
        createComponent({ provide, stubs });

        expect(findSubscriptionMangeAction().exists()).toBe(shouldShow);
      });

      it.each`
        url                  | type                              | shouldShow
        ${licenseRemovePath} | ${subscriptionTypes.LICENSE_FILE} | ${true}
        ${licenseRemovePath} | ${subscriptionTypes.CLOUD}        | ${true}
        ${''}                | ${subscriptionTypes.LICENSE_FILE} | ${false}
        ${''}                | ${subscriptionTypes.CLOUD}        | ${false}
        ${undefined}         | ${subscriptionTypes.LICENSE_FILE} | ${false}
        ${undefined}         | ${subscriptionTypes.CLOUD}        | ${false}
      `(
        'with url is $url and type is $type the remove button is shown: $shouldShow',
        ({ url, type, shouldShow }) => {
          const provide = {
            connectivityHelpURL: '',
            customersPortalUrl: '',
            subscriptionSyncPath: '',
            licenseRemovePath: url,
          };
          const props = { subscription: { ...license.ULTIMATE, type } };
          const stubs = { GlCard, SubscriptionDetailsCard };
          createComponent({ props, provide, stubs });

          expect(findLicenseRemoveAction().exists()).toBe(shouldShow);
        },
      );

      it.each`
        type                              | shouldShow
        ${subscriptionTypes.LICENSE_FILE} | ${true}
        ${subscriptionTypes.CLOUD}        | ${false}
      `(
        'with url is $url and type is $type the activate cloud license button is shown: $shouldShow',
        ({ type, shouldShow }) => {
          const props = { subscription: { ...license.ULTIMATE, type } };
          const stubs = { GlCard, SubscriptionDetailsCard };
          createComponent({ props, stubs });

          expect(findActivateSubscriptionAction().exists()).toBe(shouldShow);
        },
      );
    });

    describe('with a license file', () => {
      beforeEach(() => {
        createComponent({
          props: { subscription: licenseFile },
          stubs: {
            GlCard,
            SubscriptionDetailsCard,
          },
        });
      });

      it('does not show a button to sync the subscription', () => {
        expect(findSubscriptionSyncAction().exists()).toBe(false);
      });

      it('shows the subscription details footer', () => {
        expect(findDetailsCardFooter().exists()).toBe(true);
      });

      it('does not show the sync subscription notifications', () => {
        expect(findSubscriptionSyncNotifications().exists()).toBe(false);
      });

      it('shows modal when active subscription action clicked', () => {
        findActivateSubscriptionAction().vm.$emit('click');

        expect(glModalDirective).toHaveBeenCalledWith(modalId);
      });

      describe('subscription activation banner', () => {
        beforeEach(() => {
          createComponent({
            props: { subscription: licenseFile },
          });
        });

        it('presents a subscription activation banner', () => {
          expect(findSubscriptionActivationBanner().exists()).toBe(true);
        });

        it('calls the dismiss callback when closing the banner', () => {
          findSubscriptionActivationBanner().vm.$emit('close');

          expect(userCalloutDismissSpy).toHaveBeenCalledTimes(1);
        });

        it('shows a modal', async () => {
          expect(findSubscriptionActivationModal().props('visible')).toBe(false);

          await findSubscriptionActivationBanner().vm.$emit(ACTIVATE_SUBSCRIPTION_EVENT);

          expect(findSubscriptionActivationModal().props('visible')).toBe(true);
        });

        it('hides the banner when the proper condition applies', () => {
          createComponent({
            mountMethod: mount,
            props: { subscription: licenseFile },
            shouldShowCallout: false,
          });

          expect(findSubscriptionActivationBanner().exists()).toBe(false);
        });
      });
    });

    describe('sync a subscription success', () => {
      beforeEach(() => {
        axiosMock.onPost(subscriptionSyncPath).reply(200, { success: true });
        createComponent({ stubs: { GlCard, SubscriptionDetailsCard } });
        findSubscriptionSyncAction().vm.$emit('click');
        return waitForPromises();
      });

      it('shows a success notification', () => {
        expect(findSubscriptionSyncNotifications().props('syncStatus')).toBe(
          subscriptionSyncStatus.SYNC_PENDING,
        );
      });

      it('provides the sync status to the details card', () => {
        expect(findDetailsCards().at(0).props('syncDidFail')).toBe(false);
      });

      it('dismisses the success notification', async () => {
        findSubscriptionSyncNotifications().vm.$emit(INFO_ALERT_DISMISSED_EVENT);
        await nextTick();

        expect(findSubscriptionSyncNotifications().exists()).toBe(false);
      });
    });

    describe('sync a subscription failure', () => {
      beforeEach(() => {
        axiosMock.onPost(subscriptionSyncPath).reply(422, { success: false });
        createComponent({ stubs: { GlCard, SubscriptionDetailsCard } });
        findSubscriptionSyncAction().vm.$emit('click');
        return waitForPromises();
      });

      it('shows a failure notification', () => {
        expect(findSubscriptionSyncNotifications().props('syncStatus')).toBe(
          subscriptionSyncStatus.SYNC_FAILURE,
        );
      });

      it('provides the sync status to the details card', () => {
        expect(findDetailsCards().at(0).props('syncDidFail')).toBe(true);
      });

      it('dismisses the failure notification when retrying to sync', async () => {
        await findSubscriptionSyncAction().vm.$emit('click');

        expect(findSubscriptionSyncNotifications().exists()).toBe(false);
      });
    });
  });

  describe('with subscription history data', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows the subscription history', () => {
      expect(findDetailsHistory().exists()).toBe(true);
    });

    it('provides the correct props to the subscription history component', () => {
      expect(findDetailsHistory().props('currentSubscriptionId')).toBe(license.ULTIMATE.id);
      expect(findDetailsHistory().props('subscriptionList')).toBe(subscriptionHistory);
    });
  });

  describe('with no subscription data', () => {
    beforeEach(() => {
      createComponent({ props: { subscription: {} } });
    });

    it('does not show user info', () => {
      expect(findDetailsUserInfo().exists()).toBe(false);
    });

    it('does not show details', () => {
      createComponent({ props: { subscription: {}, subscriptionList: [] } });

      expect(findDetailsUserInfo().exists()).toBe(false);
    });

    it('does not show the subscription details footer', () => {
      expect(findDetailsCardFooter().exists()).toBe(false);
    });
  });

  describe('with no subscription history data', () => {
    it('shows the current subscription as the only history item', () => {
      createComponent({ props: { subscriptionList: [] } });

      expect(findDetailsHistory().props('')).toMatchObject({
        currentSubscriptionId: license.ULTIMATE.id,
        subscriptionList: [license.ULTIMATE],
      });
    });
  });
});
