import { GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import MockAdapter from 'axios-mock-adapter';
import Vuex from 'vuex';
import SubscriptionTable from 'ee/billings/subscriptions/components/subscription_table.vue';
import SubscriptionTableRow from 'ee/billings/subscriptions/components/subscription_table_row.vue';
import initialStore from 'ee/billings/subscriptions/store';
import * as types from 'ee/billings/subscriptions/store/mutation_types';
import { mockDataSubscription } from 'ee_jest/billings/mock_data';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { getSubscriptionData } from 'ee/billings/subscriptions/subscription_actions.customer.query.graphql';

jest.mock('~/alert');

Vue.use(VueApollo);

const defaultInjectedProps = {
  namespaceName: 'GitLab.com',
  customerPortalUrl: 'https://customers.gitlab.com/subscriptions',
  planName: 'Gold',
};

Vue.use(Vuex);

describe('SubscriptionTable component', () => {
  let store;
  let wrapper;
  let mockApollo;

  const findAddSeatsButton = () => wrapper.findByTestId('add-seats-button');
  const findManageButton = () => wrapper.findByTestId('manage-button');
  const findRenewButton = () => wrapper.findByTestId('renew-button');
  const findRefreshSeatsButton = () => wrapper.findByTestId('refresh-seats-button');
  const findSubscriptionHeader = () => wrapper.findByTestId('subscription-header');

  const createComponentWithStore = async ({
    props = {},
    provide = {},
    state = {},
    apolloMock = { subscription: { canAddSeats: true, canRenew: true } },
  } = {}) => {
    store = new Vuex.Store(initialStore());
    jest.spyOn(store, 'dispatch').mockImplementation();
    mockApollo = createMockApollo([
      [
        getSubscriptionData,
        jest.fn().mockResolvedValue({
          data: apolloMock,
        }),
      ],
    ]);

    wrapper = extendedWrapper(
      mount(SubscriptionTable, {
        store,
        apolloProvider: mockApollo,
        provide: {
          ...defaultInjectedProps,
          ...provide,
        },
        propsData: props,
      }),
    );

    Object.assign(store.state, state);
    await nextTick();
  };

  describe('when created', () => {
    beforeEach(() => {
      createComponentWithStore({
        provide: {
          planRenewHref: '/url/for/renew',
        },
        state: { isLoadingSubscription: true },
      });
    });

    it('shows loading icon', () => {
      expect(wrapper.findComponent(GlLoadingIcon).isVisible()).toBe(true);
    });

    it('dispatches the correct actions', () => {
      expect(store.dispatch).toHaveBeenCalledWith('fetchSubscription');
    });
  });

  describe('with success', () => {
    beforeEach(async () => {
      await createComponentWithStore();
      store.state.isLoadingSubscription = false;
      store.commit(types.RECEIVE_SUBSCRIPTION_SUCCESS, mockDataSubscription.gold);
      await nextTick();
    });

    it('should render the card title "GitLab.com: Gold"', () => {
      expect(findSubscriptionHeader().text()).toContain('GitLab.com: Gold');
    });

    it('should render a "Usage" and a "Billing" row', () => {
      expect(wrapper.findAllComponents(SubscriptionTableRow)).toHaveLength(2);
    });
  });

  describe('edge case: null planName is provided', () => {
    it('should skip plan name in the card title "GitLab.com:"', async () => {
      await createComponentWithStore({
        provide: {
          planName: null,
        },
        state: {
          plan: {
            code: 'Silver',
          },
        },
      });
      await waitForPromises();

      expect(findSubscriptionHeader().text()).toContain('GitLab.com:');
    });
  });

  describe('when it is a trial', () => {
    it('renders the card title', async () => {
      await createComponentWithStore({
        provide: {
          planName: 'Gold Plan',
        },
        state: {
          plan: {
            trial: true,
          },
        },
      });

      await waitForPromises();

      expect(findSubscriptionHeader().text()).toContain('GitLab.com: Gold Plan Trial');
    });

    it('renders the title for a plan with Trial in the name', async () => {
      await createComponentWithStore({
        provide: {
          planName: 'Ultimate SaaS Trial Plan',
        },
        state: {
          plan: {
            trial: true,
          },
        },
      });

      await waitForPromises();

      expect(findSubscriptionHeader().text()).toContain('GitLab.com: Ultimate SaaS Plan Trial');
    });
  });

  describe('Read only mode', () => {
    beforeEach(async () => {
      await createComponentWithStore({
        provide: {
          readOnly: true,
        },
        state: {
          isLoadingSubscription: false,
          plan: {
            code: 'bronze',
          },
          billing: {
            subscriptionEndDate: new Date(),
          },
        },
      });
    });

    it('should not render manage button', () => {
      expect(findManageButton().exists()).toBe(false);
    });

    it('should not render renew button', () => {
      expect(findRenewButton().exists()).toBe(false);
    });
  });

  describe('Manage button', () => {
    describe.each`
      planCode    | expected | testDescription
      ${'bronze'} | ${true}  | ${'renders the button'}
      ${null}     | ${false} | ${'does not render the button'}
      ${'free'}   | ${false} | ${'does not render the button'}
    `(
      'given a plan with state: planCode = $planCode',
      ({ planCode, upgradable, expected, testDescription }) => {
        beforeEach(async () => {
          await createComponentWithStore({
            state: {
              isLoadingSubscription: false,
              plan: {
                code: planCode,
                upgradable,
              },
            },
          });
        });

        it(`${testDescription}`, () => {
          expect(findManageButton().exists()).toBe(expected);
        });
      },
    );
  });

  describe('Renew button', () => {
    describe.each`
      planCode    | canRenew | expected | testDescription
      ${'silver'} | ${true}  | ${true}  | ${'renders the button'}
      ${'silver'} | ${false} | ${false} | ${'does not render the button'}
      ${null}     | ${true}  | ${false} | ${'does not render the button'}
      ${'free'}   | ${true}  | ${false} | ${'does not render the button'}
    `(
      'given a plan with state: planCode = $planCode, canRenew = $canRenew',
      ({ planCode, canRenew, expected, testDescription }) => {
        beforeEach(async () => {
          await createComponentWithStore({
            state: {
              isLoadingSubscription: false,
              plan: {
                code: planCode,
              },
            },
            apolloMock: { subscription: { canAddSeats: true, canRenew } },
          });
        });

        it(`${testDescription}`, () => {
          expect(findRenewButton().exists()).toBe(expected);
        });
      },
    );
  });

  describe('Add seats button', () => {
    describe.each`
      planCode    | canAddSeats | expected | testDescription
      ${'silver'} | ${true}     | ${true}  | ${'renders the button'}
      ${'silver'} | ${false}    | ${false} | ${'does not render the button'}
      ${null}     | ${true}     | ${false} | ${'does not render the button'}
      ${'free'}   | ${true}     | ${false} | ${'does not render the button'}
    `(
      'given a plan with state: planCode = $planCode',
      ({ planCode, canAddSeats, expected, testDescription }) => {
        beforeEach(async () => {
          createComponentWithStore({
            state: {
              isLoadingSubscription: false,
              plan: {
                code: planCode,
                upgradable: true,
              },
            },
            apolloMock: { subscription: { canAddSeats, canRenew: true } },
          });

          await waitForPromises();
        });

        it(`${testDescription}`, () => {
          expect(findAddSeatsButton().exists()).toBe(expected);
        });
      },
    );
  });

  describe('Refresh Seats feature flag is on', () => {
    let mock;

    const refreshSeatsHref = '/url';

    beforeEach(async () => {
      mock = new MockAdapter(axios);

      createComponentWithStore({
        state: {
          isLoadingSubscription: false,
        },
        provide: {
          refreshSeatsHref,
          glFeatures: { refreshBillingsSeats: true },
        },
      });

      await waitForPromises();
    });

    afterEach(() => {
      mock.restore();
    });

    it('displays the Refresh Seats button', () => {
      expect(findRefreshSeatsButton().exists()).toBe(true);
    });

    describe('when clicked', () => {
      beforeEach(async () => {
        mock.onPost(refreshSeatsHref).reply(HTTP_STATUS_OK);
        findRefreshSeatsButton().trigger('click');

        await waitForPromises();
      });

      it('makes call to BE to refresh seats', () => {
        expect(mock.history.post).toHaveLength(1);
        expect(createAlert).not.toHaveBeenCalled();
      });
    });

    describe('when clicked and BE error', () => {
      beforeEach(async () => {
        mock.onPost(refreshSeatsHref).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        findRefreshSeatsButton().trigger('click');

        await waitForPromises();
      });

      it('alerts error', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'Something went wrong trying to refresh seats',
          captureError: true,
          error: expect.any(Error),
        });
      });
    });
  });

  describe('Refresh Seats feature flag is off', () => {
    beforeEach(() => {
      createComponentWithStore({
        state: {
          isLoadingSubscription: false,
        },
        provide: {
          glFeatures: { refreshBillingsSeats: false },
        },
      });
    });

    it('does not display the Refresh Seats button', () => {
      expect(findRefreshSeatsButton().exists()).toBe(false);
    });
  });
});
