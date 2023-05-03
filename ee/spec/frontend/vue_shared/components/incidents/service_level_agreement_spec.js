import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import getIncidentStateQuery from 'ee/graphql_shared/queries/get_incident_state.query.graphql';
import ServiceLevelAgreementCell from 'ee/vue_shared/components/incidents/service_level_agreement.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { calculateRemainingMilliseconds, formatTime } from '~/lib/utils/datetime_utility';

const formatTimeActual = jest.requireActual('~/lib/utils/datetime_utility').formatTime;

jest.mock('~/lib/utils/datetime_utility', () => ({
  calculateRemainingMilliseconds: jest.fn(() => 1000),
  formatTime: jest.fn(),
}));

const mockDateString = '2020-10-15T02:42:27Z';

const ONE_MINUTE = 60 * 1000; // ms

const MINUTES = {
  FIVE: 5 * ONE_MINUTE,
  FIFTEEN: 15 * ONE_MINUTE,
  TWENTY: 20 * ONE_MINUTE,
  THIRTY_FIVE: 35 * ONE_MINUTE,
};

const issueStateResponse = (state = 'opened') => ({
  data: { project: { id: 'project-1', issue: { state, id: '1' } } },
});

describe('Service Level Agreement', () => {
  let wrapper;

  const advanceFifteenMinutes = async () => {
    jest.advanceTimersByTime(MINUTES.FIFTEEN);
    await nextTick();
  };

  function createMockApolloProvider(issueState) {
    Vue.use(VueApollo);

    const requestHandlers = [
      [getIncidentStateQuery, jest.fn().mockResolvedValue(issueStateResponse(issueState))],
    ];

    return createMockApollo(requestHandlers);
  }

  function mountComponent({ mockApollo, props } = {}) {
    wrapper = shallowMount(ServiceLevelAgreementCell, {
      apolloProvider: mockApollo,
      propsData: {
        ...props,
        issueIid: '5',
        projectPath: 'test-project',
      },
    });
  }

  beforeEach(() => {
    formatTime.mockImplementation(formatTimeActual);
  });

  describe('initial states', () => {
    it('renders an empty cell by default', () => {
      mountComponent();

      expect(wrapper.html()).toBe('');
    });

    it('renders a empty cell for an invalid date', () => {
      mountComponent({ props: { slaDueAt: 'dfsgsdfg' } });

      expect(wrapper.html()).toBe('');
    });
  });

  describe('tooltips', () => {
    const hoursInMilliseconds = 60 * 60 * 1000;
    const minutesInMilliseconds = 60 * 1000;

    it.each`
      hours | minutes | expectedMessage
      ${5}  | ${7}    | ${'5 hours, 7 minutes remaining'}
      ${5}  | ${0}    | ${'5 hours, 0 minutes remaining'}
      ${0}  | ${7}    | ${'7 minutes remaining'}
      ${0}  | ${0}    | ${'Missed SLA'}
    `(
      'returns the correct message for: hours: "$hours", minutes: "$minutes"',
      ({ hours, minutes, expectedMessage }) => {
        const testTime = hours * hoursInMilliseconds + minutes * minutesInMilliseconds;
        calculateRemainingMilliseconds.mockImplementationOnce(() => testTime);

        mountComponent({ props: { slaDueAt: mockDateString } });

        expect(wrapper.attributes('title')).toBe(expectedMessage);
      },
    );
  });

  describe('countdown timer', () => {
    it('advances a countdown timer', async () => {
      calculateRemainingMilliseconds.mockImplementationOnce(() => MINUTES.THIRTY_FIVE);

      mountComponent({ props: { slaDueAt: mockDateString } });

      expect(wrapper.text()).toBe('00:35');
      await advanceFifteenMinutes();
      expect(wrapper.text()).toBe('00:20');
      await advanceFifteenMinutes();
      expect(wrapper.text()).toBe('00:05');
    });

    it('counts down to zero', async () => {
      calculateRemainingMilliseconds.mockImplementationOnce(() => MINUTES.FIFTEEN);

      mountComponent({ props: { slaDueAt: mockDateString } });

      expect(wrapper.text()).toBe('00:15');
      await advanceFifteenMinutes();
      expect(wrapper.text()).toBe('Missed SLA');
    });

    it('cleans up a countdown timer when countdown is complete', async () => {
      calculateRemainingMilliseconds.mockImplementationOnce(() => MINUTES.FIVE);

      mountComponent({ props: { slaDueAt: mockDateString } });

      expect(wrapper.text()).toBe('00:05');
      await advanceFifteenMinutes();
      expect(wrapper.text()).toBe('Missed SLA');
      await advanceFifteenMinutes();
      expect(wrapper.text()).toBe('Missed SLA');

      // If the countdown timer was still running we would expect it to be called a second time
      expect(formatTime).toHaveBeenCalledTimes(1);
      expect(formatTime).toHaveBeenCalledWith(MINUTES.FIVE);
    });
  });

  describe('SLA text', () => {
    it('displays the correct time when displaying an SLA', () => {
      formatTime.mockImplementationOnce(() => '12:34:56');

      mountComponent({ props: { slaDueAt: mockDateString } });

      expect(wrapper.text()).toBe('12:34');
    });

    describe('text when remaining time is 0', () => {
      beforeEach(() => {
        calculateRemainingMilliseconds.mockImplementationOnce(() => 0);
      });

      it('shows the correct text when the SLA has been missed', async () => {
        const issueState = 'open';
        const mockApollo = createMockApolloProvider(issueState);
        mountComponent({ props: { slaDueAt: mockDateString }, mockApollo });

        await waitForPromises();

        expect(wrapper.text()).toBe('Missed SLA');
      });

      it('shows the correct text when the SLA has been achieved', async () => {
        const issueState = 'closed';
        const mockApollo = createMockApolloProvider(issueState);
        mountComponent({ props: { slaDueAt: mockDateString }, mockApollo });

        await waitForPromises();

        expect(wrapper.text()).toBe('Achieved SLA');
      });
    });
  });
});
