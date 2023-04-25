import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlDaterangePicker } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ViolationFilter from 'ee/compliance_dashboard/components/violations_report/violations/filter.vue';
import {
  buildDefaultViolationsFilterParams,
  convertProjectIdsToGraphQl,
} from 'ee/compliance_dashboard/utils';
import ProjectsDropdownFilter from '~/analytics/shared/components/projects_dropdown_filter.vue';
import { getDateInPast, pikadayToString } from '~/lib/utils/datetime_utility';
import { CURRENT_DATE } from 'ee/audit_events/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import getGroupProjectsQuery from 'ee/compliance_dashboard/graphql/violation_group_projects.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import { createDefaultProjects, createDefaultProjectsResponse } from '../../../mock_data';

Vue.use(VueApollo);

describe('ViolationFilter component', () => {
  let wrapper;
  const defaultQuery = buildDefaultViolationsFilterParams('');
  const groupPath = 'group-path';
  const projectIds = ['1', '2'];
  const startDate = getDateInPast(CURRENT_DATE, 20);
  const endDate = getDateInPast(CURRENT_DATE, 4);
  const dateRangeQuery = {
    mergedAfter: pikadayToString(startDate),
    mergedBefore: pikadayToString(endDate),
  };
  const defaultProjects = createDefaultProjects(2);
  const projectsResponse = createDefaultProjectsResponse(defaultProjects);

  const groupProjectsLoading = jest.fn().mockReturnValue(new Promise(() => {}));
  const groupProjectsSuccess = jest.fn().mockResolvedValue(projectsResponse);

  const findProjectsFilter = () => wrapper.findComponent(ProjectsDropdownFilter);
  const findProjectsFilterLabel = () => wrapper.findByTestId('dropdown-label');
  const findDatePicker = () => wrapper.findComponent(GlDaterangePicker);
  const findTargetBranchInput = () => wrapper.findByTestId('violations-target-branch-input');

  const mockApollo = (mockResponse = groupProjectsSuccess) =>
    createMockApollo([[getGroupProjectsQuery, mockResponse]]);

  const createComponent = (propsData = {}, mockResponse) => {
    wrapper = shallowMountExtended(ViolationFilter, {
      apolloProvider: mockApollo(mockResponse),
      propsData: {
        groupPath,
        defaultQuery,
        ...propsData,
      },
    });
  };

  describe('component behavior', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the project input label', () => {
      expect(findProjectsFilterLabel().text()).toBe('Projects');
    });

    it('configures the project filter', () => {
      expect(findProjectsFilter().props()).toMatchObject({
        groupNamespace: groupPath,
        queryParams: { first: 50, includeSubgroups: true },
        multiSelect: true,
        defaultProjects: [],
        loadingDefaultProjects: false,
      });
    });

    it('configures the date picker', () => {
      expect(findDatePicker().props()).toMatchObject({
        defaultStartDate: getDateInPast(CURRENT_DATE, 30),
        defaultEndDate: CURRENT_DATE,
        defaultMaxDate: CURRENT_DATE,
        maxDateRange: 0,
        sameDaySelection: false,
      });
    });

    it('passes the default query dates to the dates range picker', () => {
      createComponent({ defaultQuery: { ...dateRangeQuery } });

      expect(findDatePicker().props()).toMatchObject({
        defaultStartDate: startDate,
        defaultEndDate: endDate,
      });
    });

    it('hides the project filter when showProjectFilter is false', () => {
      createComponent({ showProjectFilter: false });

      expect(findProjectsFilter().exists()).toBe(false);
    });
  });

  describe('filters-changed event', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits a query with projectIds when projects have been selected', async () => {
      const expectedIds = defaultProjects.map(({ id }) => id);

      await findProjectsFilter().vm.$emit('selected', defaultProjects);

      expect(wrapper.emitted('filters-changed')).toHaveLength(1);
      expect(wrapper.emitted('filters-changed')[0]).toStrictEqual([
        { ...defaultQuery, projectIds: expectedIds },
      ]);
    });

    it('emits a query with a start and end date when a date range has been inputted', async () => {
      await findDatePicker().vm.$emit('input', { startDate, endDate });

      expect(wrapper.emitted('filters-changed')).toHaveLength(1);
      expect(wrapper.emitted('filters-changed')[0]).toStrictEqual([
        {
          ...dateRangeQuery,
        },
      ]);
    });

    it('emits a query with a target branch when it is added', async () => {
      const NEW_BRANCH = 'new-branch';
      await findTargetBranchInput().vm.$emit('submit', NEW_BRANCH);

      expect(wrapper.emitted('filters-changed')).toHaveLength(1);
      expect(wrapper.emitted('filters-changed')[0]).toStrictEqual([
        {
          ...defaultQuery,
          targetBranch: NEW_BRANCH,
        },
      ]);
    });

    it('emits a query with cleared target branch when relevant input is cleared', async () => {
      await findTargetBranchInput().vm.$emit('clear');

      expect(wrapper.emitted('filters-changed')).toHaveLength(1);
      expect(wrapper.emitted('filters-changed')[0]).toStrictEqual([
        {
          ...defaultQuery,
          targetBranch: '',
        },
      ]);
    });

    it('emits the existing filter query with mutations on each update', async () => {
      await findProjectsFilter().vm.$emit('selected', []);

      expect(wrapper.emitted('filters-changed')).toHaveLength(1);
      expect(wrapper.emitted('filters-changed')[0]).toStrictEqual([
        { ...defaultQuery, projectIds: [] },
      ]);

      await findDatePicker().vm.$emit('input', { startDate, endDate });

      expect(wrapper.emitted('filters-changed')).toHaveLength(2);
      expect(wrapper.emitted('filters-changed')[1]).toStrictEqual([
        {
          projectIds: [],
          ...dateRangeQuery,
        },
      ]);
    });
  });

  describe('projects filter', () => {
    it('fetches the project details when the default query contains projectIds', () => {
      createComponent({ defaultQuery: { ...defaultQuery, projectIds } });

      expect(groupProjectsSuccess).toHaveBeenCalledWith({
        groupPath,
        projectIds: convertProjectIdsToGraphQl(projectIds),
      });
    });

    describe('when the defaultProjects are being fetched', () => {
      it('sets the project filter to loading', () => {
        createComponent({ defaultQuery: { ...defaultQuery, projectIds } }, groupProjectsLoading);

        expect(findProjectsFilter().props()).toMatchObject({
          defaultProjects: [],
          loadingDefaultProjects: true,
        });
      });
    });

    describe('when the defaultProjects have been fetched', () => {
      it('sets the default projects on the project filter', async () => {
        createComponent({ defaultQuery: { ...defaultQuery, projectIds } });

        await waitForPromises();

        expect(findProjectsFilter().props()).toMatchObject({
          defaultProjects,
          loadingDefaultProjects: false,
        });
      });
    });
  });
});
