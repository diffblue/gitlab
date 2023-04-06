import VueApollo from 'vue-apollo';
import Vue from 'vue';
import OnboardingState from 'ee/product_analytics/onboarding/components/onboarding_state.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import getProductAnalyticsState from 'ee/product_analytics/graphql/queries/get_product_analytics_state.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';

import {
  STATE_CREATE_INSTANCE,
  SHORT_POLLING_INTERVAL,
  LONG_POLLING_INTERVAL,
  STATE_LOADING_INSTANCE,
  STATE_WAITING_FOR_EVENTS,
  STATE_COMPLETE,
} from 'ee/product_analytics/onboarding/constants';

import { TEST_PROJECT_FULL_PATH, getProductAnalyticsStateResponse } from '../../mock_data';

Vue.use(VueApollo);

describe('OnboardingState', () => {
  let wrapper;

  const fatalError = new Error('GraphQL networkError');
  const mockApolloFatalError = jest.fn().mockRejectedValue(fatalError);
  const createApolloSuccess = (state) =>
    jest.fn().mockResolvedValue(getProductAnalyticsStateResponse(state));

  const createWrapper = (props = {}, apolloMock) => {
    wrapper = shallowMountExtended(OnboardingState, {
      apolloProvider: createMockApollo([[getProductAnalyticsState, apolloMock]]),
      provide: {
        projectFullPath: TEST_PROJECT_FULL_PATH,
      },
      propsData: {
        state: '',
        pollState: false,
        ...props,
      },
    });
  };

  const advanceApolloTimers = async () => {
    jest.runOnlyPendingTimers();
    await waitForPromises();
  };

  describe('default behaviour', () => {
    beforeEach(() => {
      createWrapper({}, createApolloSuccess(STATE_CREATE_INSTANCE));
      return waitForPromises();
    });

    it('fetches the state and emits a change event', () => {
      expect(wrapper.emitted('change')).toEqual([[STATE_CREATE_INSTANCE]]);
    });
  });

  describe(`when the response is ${STATE_COMPLETE}`, () => {
    beforeEach(() => {
      createWrapper({}, createApolloSuccess(STATE_COMPLETE));
      return waitForPromises();
    });

    it('emits a "complete" event', () => {
      expect(wrapper.emitted('complete')).toEqual([[]]);
    });
  });

  describe('when a fatal error occurs', () => {
    beforeEach(() => {
      createWrapper(STATE_LOADING_INSTANCE, mockApolloFatalError);
      return waitForPromises();
    });

    it('emits an "error" event with the captured error', () => {
      expect(wrapper.emitted('error')).toEqual([[fatalError]]);
    });

    it('does not poll the query resource', async () => {
      await advanceApolloTimers();

      expect(mockApolloFatalError).toHaveBeenCalledTimes(1);
    });
  });

  describe('polling', () => {
    const mock = createApolloSuccess(STATE_CREATE_INSTANCE);

    it('polls when pollState is true', async () => {
      createWrapper({ state: STATE_CREATE_INSTANCE, pollState: true }, mock);

      await waitForPromises();

      expect(mock).toHaveBeenCalledTimes(1);
    });

    describe.each`
      state                       | polls    | pollInterval
      ${''}                       | ${false} | ${0}
      ${STATE_CREATE_INSTANCE}    | ${false} | ${0}
      ${STATE_LOADING_INSTANCE}   | ${true}  | ${SHORT_POLLING_INTERVAL}
      ${STATE_WAITING_FOR_EVENTS} | ${true}  | ${LONG_POLLING_INTERVAL}
      ${STATE_COMPLETE}           | ${false} | ${0}
    `('when the state is "$state"', ({ state, polls, pollInterval }) => {
      beforeEach(() => {
        createWrapper({ state }, mock);
        return waitForPromises();
      });

      it(`${polls ? 'polls' : 'does not poll'} the query resource`, async () => {
        await advanceApolloTimers();

        expect(mock).toHaveBeenCalledTimes(polls ? 2 : 1);
      });

      it(`sets the poll interval to ${pollInterval}`, () => {
        expect(wrapper.vm.$apollo.queries.state.pollInterval).toBe(pollInterval);
      });
    });
  });
});
