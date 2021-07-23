import { GlLoadingIcon } from '@gitlab/ui';
import { createLocalVue, mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vuex from 'vuex';
import SubscriptionTable from 'ee/billings/subscriptions/components/subscription_table.vue';
import SubscriptionTableRow from 'ee/billings/subscriptions/components/subscription_table_row.vue';
import initialStore from 'ee/billings/subscriptions/store';
import * as types from 'ee/billings/subscriptions/store/mutation_types';
import { mockDataSubscription } from 'ee_jest/billings/mock_data';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';

jest.mock('~/flash');

const defaultInjectedProps = {
  namespaceName: 'GitLab.com',
  customerPortalUrl: 'https://customers.gitlab.com/subscriptions',
  planName: 'Gold',
  freePersonalNamespace: false,
};

const localVue = createLocalVue();
localVue.use(Vuex);

describe('SubscriptionTable component', () => {
  let store;
  let wrapper;

  const findAddSeatsButton = () => wrapper.findByTestId('add-seats-button');
  const findManageButton = () => wrapper.findByTestId('manage-button');
  const findRenewButton = () => wrapper.findByTestId('renew-button');
  const findUpgradeButton = () => wrapper.findByTestId('upgrade-button');
  const findRefreshSeatsButton = () => wrapper.findByTestId('refresh-seats-button');

  const createComponentWithStore = ({ props = {}, provide = {}, state = {} } = {}) => {
    store = new Vuex.Store(initialStore());
    jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = extendedWrapper(
      mount(SubscriptionTable, {
        store,
        localVue,
        provide: {
          ...defaultInjectedProps,
          ...provide,
        },
        propsData: props,
      }),
    );

    Object.assign(store.state, state);
    return wrapper.vm.$nextTick();
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when created', () => {
    beforeEach(() => {
      createComponentWithStore({
        provide: {
          planUpgradeHref: '/url/',
          planRenewHref: '/url/for/renew',
        },
        state: { isLoadingSubscription: true },
      });
    });

    it('shows loading icon', () => {
      expect(wrapper.find(GlLoadingIcon).isVisible()).toBeTruthy();
    });

    it('dispatches the correct actions', () => {
      expect(store.dispatch).toHaveBeenCalledWith('fetchSubscription');
    });
  });

  describe('with success', () => {
    beforeEach(() => {
      createComponentWithStore();
      store.state.isLoadingSubscription = false;
      store.commit(types.RECEIVE_SUBSCRIPTION_SUCCESS, mockDataSubscription.gold);
      return wrapper.vm.$nextTick();
    });

    it('should render the card title "GitLab.com: Gold"', () => {
      expect(wrapper.findByTestId('subscription-header').text()).toContain('GitLab.com: Gold');
    });

    it('should render a "Usage" and a "Billing" row', () => {
      expect(wrapper.findAll(SubscriptionTableRow)).toHaveLength(2);
    });
  });

  describe('when it is a trial', () => {
    it('should render the card title "GitLab.com: Trial"', async () => {
      await createComponentWithStore({
        state: {
          plan: {
            code: 'gold',
            trial: true,
          },
        },
      });
      expect(wrapper.findByTestId('subscription-header').text()).toContain('Trial');
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
        beforeEach(() => {
          createComponentWithStore({
            state: {
              isLoadingSubscription: false,
              plan: {
                code: planCode,
                upgradable,
              },
            },
          });
        });

        it(testDescription, () => {
          expect(findManageButton().exists()).toBe(expected);
        });
      },
    );
  });

  describe('Renew button', () => {
    describe.each`
      planCode    | trial    | expected | testDescription
      ${'silver'} | ${false} | ${true}  | ${'renders the button'}
      ${'silver'} | ${true}  | ${false} | ${'does not render the button'}
      ${null}     | ${false} | ${false} | ${'does not render the button'}
      ${'free'}   | ${false} | ${false} | ${'does not render the button'}
    `(
      'given a plan with state: planCode = $planCode, trial = $trial',
      ({ planCode, trial, expected, testDescription }) => {
        beforeEach(() => {
          createComponentWithStore({
            state: {
              isLoadingSubscription: false,
              plan: {
                code: planCode,
                trial,
              },
              billing: {
                subscriptionEndDate: new Date(),
              },
            },
          });
        });

        it(testDescription, () => {
          expect(findRenewButton().exists()).toBe(expected);
        });
      },
    );

    describe('when subscriptionEndDate is more than 15 days', () => {
      beforeEach(() => {
        const today = new Date();
        const subscriptionEndDate = today.setDate(today.getDate() + 16);

        createComponentWithStore({
          state: {
            isLoadingSubscription: false,
            plan: {
              code: mockDataSubscription.planCode,
              trial: false,
            },
            billing: {
              subscriptionEndDate,
            },
          },
        });
      });

      it('does not display the renew button', () => {
        expect(findRenewButton().exists()).toBe(false);
      });
    });
  });

  describe('Add seats button', () => {
    describe.each`
      planCode    | expected | testDescription
      ${'silver'} | ${true}  | ${'renders the button'}
      ${null}     | ${false} | ${'does not render the button'}
      ${'free'}   | ${false} | ${'does not render the button'}
    `(
      'given a plan with state: planCode = $planCode',
      ({ planCode, expected, testDescription }) => {
        beforeEach(() => {
          createComponentWithStore({
            state: {
              isLoadingSubscription: false,
              plan: {
                code: planCode,
                upgradable: true,
              },
            },
          });
        });

        it(testDescription, () => {
          expect(findAddSeatsButton().exists()).toBe(expected);
        });
      },
    );
  });

  describe('Upgrade button', () => {
    describe.each`
      planCode    | upgradable | freePersonalNamespace | expected
      ${null}     | ${false}   | ${false}              | ${true}
      ${null}     | ${true}    | ${false}              | ${true}
      ${null}     | ${false}   | ${true}               | ${false}
      ${null}     | ${true}    | ${true}               | ${false}
      ${'free'}   | ${false}   | ${false}              | ${true}
      ${'free'}   | ${true}    | ${false}              | ${true}
      ${'free'}   | ${false}   | ${true}               | ${false}
      ${'free'}   | ${true}    | ${true}               | ${false}
      ${'bronze'} | ${false}   | ${false}              | ${false}
      ${'bronze'} | ${true}    | ${false}              | ${true}
      ${'bronze'} | ${false}   | ${true}               | ${false}
      ${'bronze'} | ${true}    | ${true}               | ${false}
    `(
      'given a plan with state: planCode = $planCode, upgradable = $upgradable, freePersonalNamespace = $freePersonalNamespace',
      ({ planCode, upgradable, freePersonalNamespace, expected }) => {
        beforeEach(() => {
          createComponentWithStore({
            provide: {
              planUpgradeHref: '',
              freePersonalNamespace,
            },
            state: {
              isLoadingSubscription: false,
              plan: {
                code: planCode,
                upgradable,
              },
            },
          });
        });

        const testDescription =
          expected === true ? 'renders the button' : 'does not render the button';

        it(testDescription, () => {
          expect(findUpgradeButton().exists()).toBe(expected);
        });
      },
    );
  });

  describe('Refresh Seats feature flag is on', () => {
    let mock;

    const refreshSeatsHref = '/url';

    beforeEach(() => {
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
    });

    afterEach(() => {
      mock.restore();
    });

    it('displays the Refresh Seats button', () => {
      expect(findRefreshSeatsButton().exists()).toBe(true);
    });

    describe('when clicked', () => {
      beforeEach(async () => {
        mock.onPost(refreshSeatsHref).reply(200);
        findRefreshSeatsButton().trigger('click');

        await waitForPromises();
      });

      it('makes call to BE to refresh seats', () => {
        expect(mock.history.post).toHaveLength(1);
        expect(createFlash).not.toHaveBeenCalled();
      });
    });

    describe('when clicked and BE error', () => {
      beforeEach(async () => {
        mock.onPost(refreshSeatsHref).reply(500);
        findRefreshSeatsButton().trigger('click');

        await waitForPromises();
      });

      it('flashes error', () => {
        expect(createFlash).toHaveBeenCalledWith({
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
