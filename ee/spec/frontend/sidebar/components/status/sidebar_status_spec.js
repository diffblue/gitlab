import { createLocalVue, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import SidebarStatus from 'ee/sidebar/components/status/sidebar_status.vue';
import Status from 'ee/sidebar/components/status/status.vue';
import { healthStatusQueries } from 'ee/sidebar/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import { getHealthStatusMutationResponse, getHealthStatusQueryResponse } from './mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

const createQueryHandler = ({ state, healthStatus }) =>
  jest.fn().mockResolvedValue(getHealthStatusQueryResponse({ state, healthStatus }));
const createMutationHandler = ({ healthStatus }) =>
  jest.fn().mockResolvedValue(getHealthStatusMutationResponse({ healthStatus }));

let queryHandler;
let mutationHandler;

function createMockApolloProvider({ healthStatus, state }) {
  queryHandler = createQueryHandler({ healthStatus, state });
  mutationHandler = createMutationHandler({ healthStatus });
  return createMockApollo([
    [healthStatusQueries.issue.query, queryHandler],
    [healthStatusQueries.issue.mutation, mutationHandler],
  ]);
}

describe('SidebarStatus', () => {
  let wrapper;

  const createWrapper = ({
    issuableType = 'issue',
    state = 'opened',
    healthStatus = 'onTrack',
  } = {}) => {
    wrapper = shallowMount(SidebarStatus, {
      localVue,
      propsData: {
        issuableType,
        iid: '1',
        fullPath: 'foo/bar',
        canUpdate: true,
      },
      apolloProvider: createMockApolloProvider({ healthStatus, state }),
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('computed', () => {
    describe.each`
      state         | isOpen
      ${'opened'}   | ${true}
      ${'reopened'} | ${true}
      ${'closed'}   | ${false}
    `('isOpen', ({ state, isOpen }) => {
      beforeEach(() => {
        createWrapper({ state });
      });

      it(`returns ${isOpen} when issue is ${state}`, () => {
        expect(wrapper.vm.isOpen).toBe(isOpen);
      });
    });
  });

  describe('Status child component', () => {
    beforeEach(() => {});

    it('renders Status component', () => {
      expect(wrapper.findComponent(Status).exists()).toBe(true);
    });

    it('calls apollo mutate when receiving an onDropdownClick event from Status component', () => {
      wrapper.findComponent(Status).vm.$emit('onDropdownClick', 'onTrack');

      const variables = {
        projectPath: 'foo/bar',
        iid: '1',
        healthStatus: 'onTrack',
      };

      expect(mutationHandler).toHaveBeenCalledWith(expect.objectContaining(variables));
    });
  });
});
