import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlSkeletonLoader } from '@gitlab/ui';
import { TYPENAME_GROUP, TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { METRICS_WITHOUT_LABEL_FILTERING } from 'ee/analytics/dashboards/constants';
import DoraVisualization from 'ee/analytics/dashboards/components/dora_visualization.vue';
import ComparisonChartLabels from 'ee/analytics/dashboards/components/comparison_chart_labels.vue';
import ComparisonChart from 'ee/analytics/dashboards/components/comparison_chart.vue';
import getGroupOrProjectQuery from 'ee/analytics/dashboards/graphql/get_group_or_project.query.graphql';
import filterLabelsQueryBuilder from 'ee/analytics/dashboards/graphql/filter_labels_query_builder';
import { mockFilterLabelsResponse } from '../helpers';

Vue.use(VueApollo);

describe('DoraVisualization', () => {
  let wrapper;

  const mockGroup = {
    id: 'gid://gitlab/Group/10',
    name: 'Group 10',
    webUrl: 'gdk.test/groups/group-10',
    __typename: TYPENAME_GROUP,
  };
  const mockProject = {
    id: 'gid://gitlab/Project/20',
    name: 'Project 20',
    webUrl: 'gdk.test/group-10/project-20',
    __typename: TYPENAME_PROJECT,
  };

  const createWrapper = async ({
    props = {},
    group = null,
    project = null,
    filterLabelsResolver = null,
  } = {}) => {
    const filterLabels = props.data?.filter_labels || [];
    const apolloProvider = createMockApollo([
      [getGroupOrProjectQuery, jest.fn().mockResolvedValue({ data: { group, project } })],
      [
        filterLabelsQueryBuilder(filterLabels, !group),
        filterLabelsResolver ||
          jest.fn().mockResolvedValue({ data: mockFilterLabelsResponse(filterLabels) }),
      ],
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
  const findNamespaceErrorAlert = () => wrapper.findByTestId('load-namespace-error');
  const findLabelsErrorAlert = () => wrapper.findByTestId('load-labels-error');
  const findComparisonChartLabels = () => wrapper.findComponent(ComparisonChartLabels);
  const findComparisonChartLabelTitles = () =>
    wrapper
      .findComponent(ComparisonChartLabels)
      .props('labels')
      .map(({ title }) => title);
  const findComparisonChart = () => wrapper.findComponent(ComparisonChart);
  const findTitle = () => wrapper.findByTestId('comparison-chart-title');

  it('shows a loading skeleton when fetching group/project details', () => {
    createWrapper();
    expect(findSkeletonLoader().exists()).toBe(true);
  });

  it('shows an error alert if it failed to fetch group/project', async () => {
    await createWrapper();
    expect(findNamespaceErrorAlert().exists()).toBe(true);
    expect(findNamespaceErrorAlert().text()).toBe(
      'Failed to load comparison chart for Namespace: test/one',
    );
  });

  it('passes data attributes to the comparison chart', async () => {
    const requestPath = 'test';
    const excludeMetrics = ['one', 'two'];
    await createWrapper({
      props: { data: { namespace: requestPath, exclude_metrics: excludeMetrics } },
      group: mockGroup,
    });
    expect(findComparisonChart().props()).toEqual(
      expect.objectContaining({
        requestPath,
        excludeMetrics,
      }),
    );
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

  describe('filter_labels', () => {
    const namespace = 'test';

    it('does not show labels when not defined', async () => {
      await createWrapper({
        props: { data: { namespace } },
        group: mockGroup,
      });
      expect(findComparisonChartLabels().exists()).toBe(false);
      expect(findComparisonChart().props('filterLabels')).toEqual([]);
    });

    it('does not show labels when empty', async () => {
      await createWrapper({
        props: { data: { namespace, filter_labels: [] } },
        group: mockGroup,
      });
      expect(findComparisonChartLabels().exists()).toBe(false);
      expect(findComparisonChart().props('filterLabels')).toEqual([]);
    });

    it('shows an error alert if it failed to fetch labels', async () => {
      const testLabels = ['testA', 'testB'];
      await createWrapper({
        props: { data: { namespace, filter_labels: testLabels } },
        filterLabelsResolver: jest.fn().mockRejectedValue(),
        group: mockGroup,
      });

      expect(findComparisonChartLabels().exists()).toBe(false);
      expect(findComparisonChart().exists()).toBe(false);
      expect(findLabelsErrorAlert().exists()).toBe(true);
      expect(findLabelsErrorAlert().text()).toBe(
        'Failed to load labels matching the filter: testA, testB',
      );
    });

    it('removes duplicate labels from the result', async () => {
      const dupLabel = 'testA';
      const testLabels = [dupLabel, dupLabel, dupLabel];
      await createWrapper({
        props: { data: { namespace, filter_labels: testLabels } },
        group: mockGroup,
      });

      expect(findComparisonChartLabels().exists()).toBe(true);
      expect(findComparisonChartLabelTitles()).toEqual([dupLabel]);
      expect(findComparisonChartLabels().props('webUrl')).toEqual(mockGroup.webUrl);
      expect(findComparisonChart().props('filterLabels')).toEqual([dupLabel]);
    });

    it('in addition to `exclude_metrics`, will exclude incompatible metrics', async () => {
      const testLabels = ['testA'];
      const excludeMetrics = ['cycle_time'];
      await createWrapper({
        props: { data: { namespace, filter_labels: testLabels, exclude_metrics: excludeMetrics } },
        group: mockGroup,
      });

      expect(findComparisonChart().props()).toEqual(
        expect.objectContaining({
          filterLabels: testLabels,
          excludeMetrics: [...excludeMetrics, ...METRICS_WITHOUT_LABEL_FILTERING],
        }),
      );
    });
  });
});
