import { createLocalVue, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import RunnerList from '~/runner/components/runner_list.vue';
import RunnerManualSetupHelp from '~/runner/components/runner_manual_setup_help.vue';
import RunnerTypeHelp from '~/runner/components/runner_type_help.vue';
import getGroupRunnersQuery from '~/runner/graphql/get_group_runners.query.graphql';
import GroupRunnersApp from '~/runner/group_runners/group_runners_app.vue';
import { groupRunnersData } from '../mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

const mockGroupFullPath = 'group1';
const mockRegistrationToken = 'AABBCC';

describe('GroupRunnersApp', () => {
  let wrapper;
  let mockGroupRunnersQuery;

  const findRunnerTypeHelp = () => wrapper.findComponent(RunnerTypeHelp);
  const findRunnerManualSetupHelp = () => wrapper.findComponent(RunnerManualSetupHelp);
  const findRunnerList = () => wrapper.findComponent(RunnerList);

  const createComponent = ({ mountFn = shallowMount } = {}) => {
    const handlers = [[getGroupRunnersQuery, mockGroupRunnersQuery]];

    wrapper = mountFn(GroupRunnersApp, {
      localVue,
      apolloProvider: createMockApollo(handlers),
      propsData: {
        registrationToken: mockRegistrationToken,
        groupFullPath: mockGroupFullPath,
      },
    });
  };

  beforeEach(async () => {
    mockGroupRunnersQuery = jest.fn().mockResolvedValue(groupRunnersData);

    createComponent();
    await waitForPromises();
  });

  it('shows the runner type help', () => {
    expect(findRunnerTypeHelp().exists()).toBe(true);
  });

  it('shows the runner setup instructions', () => {
    expect(findRunnerManualSetupHelp().exists()).toBe(true);
    expect(findRunnerManualSetupHelp().props('registrationToken')).toBe(mockRegistrationToken);
  });

  it('shows the runners list', () => {
    expect(findRunnerList().props('runners')).toEqual(groupRunnersData.data.group.runners.nodes);
  });
});
