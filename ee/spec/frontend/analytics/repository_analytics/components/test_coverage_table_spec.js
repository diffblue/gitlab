import { GlTableLite } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import SelectProjectsDropdown from 'ee/analytics/repository_analytics/components/select_projects_dropdown.vue';
import TestCoverageTable from 'ee/analytics/repository_analytics/components/test_coverage_table.vue';
import getGroupProjects from 'ee/analytics/repository_analytics/graphql/queries/get_group_projects.query.graphql';
import getProjectsTestCoverage from 'ee/analytics/repository_analytics/graphql/queries/get_projects_test_coverage.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import Api from '~/api';
import { getTimeago } from '~/lib/utils/datetime_utility';
import DownloadTestCoverage from 'ee/analytics/repository_analytics/components/download_test_coverage.vue';
import { defaultTestCoverageTable, projects } from '../mock_data';

jest.mock('~/api.js');

Vue.use(VueApollo);

describe('Test coverage table component', () => {
  let wrapper;
  let getProjectsTestCoverageSpy;
  const timeago = getTimeago();

  const findProjectsDropdown = () => wrapper.findComponent(SelectProjectsDropdown);
  const findEmptyState = () => wrapper.findByTestId('test-coverage-table-empty-state');
  const findLoadingState = () => wrapper.findByTestId('test-coverage-loading-state');
  const findTable = () => wrapper.findComponent(GlTableLite);
  const findTableRows = () => findTable().findAll('tbody tr');
  const findProjectNameById = (id) => wrapper.findByTestId(`${id}-name`);
  const findProjectAverageById = (id) => wrapper.findByTestId(`${id}-average`);
  const findProjectCountById = (id) => wrapper.findByTestId(`${id}-count`);
  const findProjectDateById = (id) => wrapper.findByTestId(`${id}-date`);

  const clickSelectAllProjects = async () => {
    await findProjectsDropdown().vm.$emit('select-all-projects');
    jest.runOnlyPendingTimers();
    await waitForPromises();
  };

  const createComponent = ({ glFeatures = {}, mockData = {}, mountFn = shallowMount } = {}) => {
    const mockApollo = createMockApollo([
      [getGroupProjects, jest.fn().mockResolvedValue()],
      [getProjectsTestCoverage, getProjectsTestCoverageSpy],
    ]);

    wrapper = extendedWrapper(
      mountFn(TestCoverageTable, {
        apolloProvider: mockApollo,
        data() {
          return {
            ...defaultTestCoverageTable,
            ...mockData,
          };
        },
        provide: {
          glFeatures,
          groupFullPath: 'gitlab-org',
        },
      }),
    );
  };

  beforeEach(() => {
    getProjectsTestCoverageSpy = jest.fn().mockResolvedValue({
      data: { group: { id: '1', projects: { nodes: projects } } },
    });
  });

  describe('when code coverage is empty', () => {
    it('renders empty state', () => {
      createComponent();

      expect(findEmptyState().exists()).toBe(true);
    });
  });

  describe('when query is loading', () => {
    it('renders loading state', () => {
      createComponent({ mockData: { isLoading: true } });

      expect(findLoadingState().exists()).toBe(true);
    });
  });

  describe('when code coverage is available', () => {
    it('renders the download test coverage component', () => {
      createComponent({ mountFn: mount });

      expect(wrapper.findComponent(DownloadTestCoverage).exists()).toBe(true);
    });

    it('renders coverage table', async () => {
      const {
        id,
        name,
        codeCoverageSummary: { averageCoverage, coverageCount, lastUpdatedOn },
      } = projects[0];
      createComponent({ mountFn: mount });

      await clickSelectAllProjects();

      expect(getProjectsTestCoverageSpy).toHaveBeenCalled();

      expect(findTable().exists()).toBe(true);
      expect(findProjectNameById(id).text()).toBe(name);
      expect(findProjectAverageById(id).text()).toBe(`${averageCoverage}%`);
      expect(findProjectCountById(id).text()).toBe(coverageCount);
      expect(findProjectDateById(id).text()).toBe(timeago.format(lastUpdatedOn));
    });

    it('sorts the table by the most recently updated report', async () => {
      const project = projects[0];
      const today = '2021-01-30T20:34:14.302Z';
      const yesterday = '2021-01-29T20:34:14.302Z';
      getProjectsTestCoverageSpy = jest.fn().mockResolvedValue({
        data: {
          group: {
            id: '1',
            projects: {
              nodes: [
                {
                  ...project,
                  name: 'should be last',
                  id: 1,
                  codeCoverageSummary: {
                    ...project.codeCoverageSummary,
                    lastUpdatedOn: yesterday,
                  },
                },
                {
                  ...project,
                  name: 'should be first',
                  id: 2,
                  codeCoverageSummary: {
                    ...project.codeCoverageSummary,
                    lastUpdatedOn: today,
                  },
                },
              ],
            },
          },
        },
      });

      createComponent({ mountFn: mount });

      await clickSelectAllProjects();

      expect(findTable().exists()).toBe(true);
      expect(findTableRows().at(0).text()).toContain('should be first');
      expect(findTableRows().at(1).text()).toContain('should be last');
    });

    it('renders the correct link', async () => {
      const {
        id,
        fullPath,
        repository: { rootRef },
      } = projects[0];
      const expectedPath = `/${fullPath}/-/graphs/${rootRef}/charts`;
      createComponent({ mountFn: mount });

      await clickSelectAllProjects();

      expect(findTable().exists()).toBe(true);
      expect(findProjectNameById(id).attributes('href')).toBe(expectedPath);
    });
  });

  describe('with usage metrics', () => {
    it('tracks i_testing_group_code_coverage_project_click_total metric', async () => {
      const { id } = projects[0];
      createComponent({ mountFn: mount });

      await clickSelectAllProjects();

      findProjectNameById(id).trigger('click');

      expect(Api.trackRedisHllUserEvent).toHaveBeenCalledTimes(1);
      expect(Api.trackRedisHllUserEvent).toHaveBeenCalledWith(
        wrapper.vm.$options.servicePingProjectEvent,
      );
    });
  });
});
