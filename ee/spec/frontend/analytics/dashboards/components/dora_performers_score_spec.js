import { GlStackedColumnChart } from '@gitlab/ui/dist/charts';
import { GlAlert, GlCard, GlSkeletonLoader } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import DoraPerformersScore from 'ee/analytics/dashboards/components/dora_performers_score.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import groupDoraPerformanceScoreCountsQuery from 'ee/analytics/dashboards/graphql/group_dora_performance_score_counts.query.graphql';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { DORA_PERFORMERS_SCORE_CHART_COLOR_PALETTE } from 'ee/analytics/dashboards/constants';
import getGroupOrProject from 'ee/analytics/dashboards/graphql/get_group_or_project.query.graphql';
import { TYPENAME_GROUP, TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { mockGraphqlDoraPerformanceScoreCountsResponse } from '../helpers';
import {
  mockDoraPerformersScoreChartData,
  mockEmptyDoraPerformersScoreResponseData,
} from '../mock_data';

Vue.use(VueApollo);

describe('DoraPerformersScore', () => {
  const fullPath = 'toolbox';
  const groupName = 'Toolbox';
  const mockData = { namespace: fullPath };
  const mockProjectsCount = 70;
  const mockGroup = {
    __typename: TYPENAME_GROUP,
    id: 'gid://gitlab/Group/22',
    name: groupName,
    webUrl: 'gdk.test/groups/toolbox',
  };
  const mockProject = {
    __typename: TYPENAME_PROJECT,
    id: 'gid://gitlab/Project/22',
    name: 'Hammer',
    webUrl: 'gdk.test/toolbox/hammer',
  };
  const doraPerformanceScoreCountsSuccess = mockGraphqlDoraPerformanceScoreCountsResponse({
    projectsCount: mockProjectsCount,
  });
  const doraPerformanceScoreCountsEmpty = mockGraphqlDoraPerformanceScoreCountsResponse({
    mockDataResponse: mockEmptyDoraPerformersScoreResponseData,
  });
  const doraPerformanceScoreCountsEmptyDataset = mockGraphqlDoraPerformanceScoreCountsResponse({
    mockDataResponse: [],
  });
  const queryError = jest.fn().mockRejectedValueOnce(new Error('Something went wrong'));
  const loadingErrorMessage = `Failed to load DORA performance scores for Namespace: ${fullPath}`;
  const projectNamespaceErrorMessage =
    'This visualization is not supported for project namespaces.';
  const mockGroupBy = [
    'Deployment Frequency (Velocity)',
    'Lead Time for Changes (Velocity)',
    'Time to Restore Service (Quality)',
    'Change Failure Rate (Quality)',
  ];
  const defaultGlFeatures = { doraPerformersScorePanel: true };
  const panelTitleWithProjectsCount = (projectsCount = 0) =>
    `Total projects (${projectsCount}) by DORA performers score for ${groupName} group`;

  let wrapper;
  let mockApollo;

  const createWrapper = async ({
    props = {},
    group = mockGroup,
    project = null,
    doraPerformanceScoreCountsHandler = doraPerformanceScoreCountsSuccess,
    glFeatures = defaultGlFeatures,
  } = {}) => {
    mockApollo = createMockApollo([
      [groupDoraPerformanceScoreCountsQuery, doraPerformanceScoreCountsHandler],
      [getGroupOrProject, jest.fn().mockResolvedValue({ data: { group, project } })],
    ]);

    wrapper = shallowMountExtended(DoraPerformersScore, {
      apolloProvider: mockApollo,
      propsData: {
        data: mockData,
        ...props,
      },
      stubs: {
        GlCard,
      },
      provide: {
        glFeatures,
      },
    });

    await waitForPromises();
  };

  const findDoraPerformersScorePanel = () => wrapper.findByTestId('dora-performers-score-panel');
  const findDoraPerformersScoreChart = () => wrapper.findComponent(GlStackedColumnChart);
  const findDoraPerformersScorePanelTitle = () =>
    wrapper.findByTestId('dora-performers-score-panel-title');
  const findChartSkeletonLoader = () => wrapper.findComponent(ChartSkeletonLoader);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findAlert = () => wrapper.findComponent(GlAlert);

  describe('default', () => {
    beforeEach(async () => {
      await createWrapper();
    });

    afterEach(() => {
      mockApollo = null;
    });

    it('displays panel title with total project count', () => {
      expect(findDoraPerformersScorePanelTitle().text()).toBe(
        panelTitleWithProjectsCount(mockProjectsCount),
      );
    });

    it.each`
      prop               | propValue
      ${'bars'}          | ${mockDoraPerformersScoreChartData}
      ${'presentation'}  | ${'tiled'}
      ${'groupBy'}       | ${mockGroupBy}
      ${'xAxisType'}     | ${'category'}
      ${'xAxisTitle'}    | ${''}
      ${'yAxisTitle'}    | ${''}
      ${'customPalette'} | ${DORA_PERFORMERS_SCORE_CHART_COLOR_PALETTE}
    `("sets '$prop' prop to '$propValue' in the chart", ({ prop, propValue }) => {
      expect(findDoraPerformersScoreChart().props(prop)).toStrictEqual(propValue);
    });
  });

  describe('when fetching data', () => {
    beforeEach(() => {
      createWrapper();
    });

    afterEach(() => {
      mockApollo = null;
    });

    it('renders chart skeleton loader', () => {
      expect(findChartSkeletonLoader().exists()).toBe(true);
    });

    it('renders skeleton loader instead of panel title', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
      expect(findDoraPerformersScorePanelTitle().exists()).toBe(false);
    });
  });

  describe.each`
    error                                         | props                                                | expectedErrorMessage
    ${'it fails to fetch DORA performers scores'} | ${{ doraPerformanceScoreCountsHandler: queryError }} | ${loadingErrorMessage}
    ${'namespace is `null`'}                      | ${{ group: null }}                                   | ${loadingErrorMessage}
    ${'namespace is project'}                     | ${{ group: null, project: mockProject }}             | ${projectNamespaceErrorMessage}
  `('when $error', ({ props, expectedErrorMessage }) => {
    beforeEach(async () => {
      await createWrapper(props);
    });

    afterEach(() => {
      mockApollo = null;
    });

    it('displays default panel title', () => {
      const panelTitle = 'Total projects by DORA performers score';
      expect(findDoraPerformersScorePanelTitle().text()).toBe(panelTitle);
    });

    it('renders alert component', () => {
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toBe(expectedErrorMessage);
    });
  });

  describe.each`
    noData                                              | response
    ${'there are no DORA performance score counts'}     | ${doraPerformanceScoreCountsEmpty}
    ${'DORA performance score counts dataset is empty'} | ${doraPerformanceScoreCountsEmptyDataset}
  `('when $noData', ({ response }) => {
    beforeEach(async () => {
      await createWrapper({ doraPerformanceScoreCountsHandler: response });
    });

    afterEach(() => {
      mockApollo = null;
    });

    it('displays panel title with `0` total projects', () => {
      expect(findDoraPerformersScorePanelTitle().text()).toBe(panelTitleWithProjectsCount());
    });

    it('displays empty state message', () => {
      const noDataMessage = `No data available for Namespace: ${fullPath}`;
      expect(wrapper.findByText(noDataMessage).exists()).toBe(true);
    });
  });

  it('does not render if "doraPerformersScorePanel" feature flag is disabled', async () => {
    await createWrapper({ glFeatures: { doraPerformersScorePanel: false } });

    expect(findDoraPerformersScorePanel().exists()).toBe(false);
  });
});
