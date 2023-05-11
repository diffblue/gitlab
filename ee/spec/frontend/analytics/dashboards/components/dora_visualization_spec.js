import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlSkeletonLoader, GlAlert } from '@gitlab/ui';
import { TYPENAME_GROUP, TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import DoraVisualization from 'ee/analytics/dashboards/components/dora_visualization.vue';
import ComparisonChart from 'ee/analytics/dashboards/components/comparison_chart.vue';
import getGroupOrProjectQuery from 'ee/analytics/dashboards/graphql/get_group_or_project.query.graphql';

Vue.use(VueApollo);

describe('DoraVisualization', () => {
  let wrapper;

  const mockGroup = { id: 'gid://gitlab/Group/10', name: 'Group 10', __typename: TYPENAME_GROUP };
  const mockProject = {
    id: 'gid://gitlab/Project/20',
    name: 'Project 20',
    __typename: TYPENAME_PROJECT,
  };

  const createWrapper = async ({ props = {}, group = null, project = null } = {}) => {
    const apolloProvider = createMockApollo([
      [getGroupOrProjectQuery, jest.fn().mockResolvedValue({ data: { group, project } })],
    ]);

    wrapper = shallowMountExtended(DoraVisualization, {
      apolloProvider,
      propsData: {
        data: { namespace: 'test/one' },
        ...props,
      },
    });

    await waitForPromises();
  };

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findComparisonChart = () => wrapper.findComponent(ComparisonChart);
  const findTitle = () => wrapper.findByTestId('comparison-chart-title');

  it('shows a loading skeleton when fetching group/project details', () => {
    createWrapper();
    expect(findSkeletonLoader().exists()).toBe(true);
  });

  it('shows an error alert if it failed to fetch group/project', async () => {
    await createWrapper();
    expect(findAlert().exists()).toBe(true);
    expect(findAlert().text()).toBe('Failed to load comparison chart for Namespace: test/one');
  });

  it('renders a group with the default title', async () => {
    await createWrapper({ group: mockGroup });
    expect(findTitle().text()).toEqual(`Metrics comparison for ${mockGroup.name} group`);
    expect(findComparisonChart().props('isProject')).toBe(false);
  });

  it('renders a project with the default title', async () => {
    await createWrapper({ project: mockProject });
    expect(findTitle().text()).toEqual(`Metrics comparison for ${mockProject.name} project`);
    expect(findComparisonChart().props('isProject')).toBe(true);
  });

  it('renders the custom title from the `title` prop', async () => {
    const title = 'custom title';
    await createWrapper({ props: { title }, group: mockGroup });
    expect(findTitle().text()).toEqual(title);
  });
});
