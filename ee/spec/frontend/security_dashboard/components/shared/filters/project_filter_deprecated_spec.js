import { GlIntersectionObserver, GlLoadingIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import FilterBody from 'ee/security_dashboard/components/shared/filters/filter_body.vue';
import FilterItem from 'ee/security_dashboard/components/shared/filters/filter_item.vue';
import ProjectFilterDeprecated from 'ee/security_dashboard/components/shared/filters/project_filter_deprecated.vue';
import groupProjectsQuery from 'ee/security_dashboard/graphql/queries/group_projects.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import { projectFilter, PROJECT_LOADING_ERROR_MESSAGE } from 'ee/security_dashboard/helpers';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert } from '~/flash';

Vue.use(VueApollo);

jest.mock('~/flash');

const projects = [
  { id: 1, name: 'Project 1' },
  { id: 2, name: 'Project 2' },
];
const groupFullPath = 'group';
// This is needed so that fetchMore() won't throw an error when it's not mocked out. We can't mock
// it out because we're testing that fetchMore() will make the query start loading, which in turn
// shows the loading spinner.
const cacheConfig = {
  typePolicies: { Query: { fields: { group: { merge: true } } } },
};
const getProjectsRequestHandler = ({ hasNextPage = true } = {}) =>
  jest.fn().mockResolvedValue({
    data: {
      group: {
        id: 'group',
        projects: {
          edges: projects.map((node) => ({ node })),
          pageInfo: { hasNextPage, endCursor: 'abc' },
        },
      },
    },
  });
const defaultProjectsRequestHandler = getProjectsRequestHandler();

describe('Project Filter Deprecated component', () => {
  let wrapper;

  const createWrapper = ({ projectsRequestHandler = defaultProjectsRequestHandler } = {}) => {
    wrapper = shallowMountExtended(ProjectFilterDeprecated, {
      apolloProvider: createMockApollo(
        [[groupProjectsQuery, projectsRequestHandler]],
        {},
        cacheConfig,
      ),
      propsData: {
        filter: projectFilter,
      },
      provide: {
        groupFullPath,
        dashboardType: DASHBOARD_TYPES.GROUP,
      },
    });
  };

  const findFilterBody = () => wrapper.findComponent(FilterBody);
  const findIntersectionObserver = () => wrapper.findComponent(GlIntersectionObserver);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const isLoadingIconVisible = () => !findLoadingIcon().classes('gl-visibility-hidden');
  const findAllProjectsDropdownItem = () => wrapper.findByTestId('allOption');

  const findProjectDropdownItems = () =>
    wrapper
      .findAllComponents(FilterItem)
      .filter((x) => x.attributes('data-testid') !== 'allOption');

  // Create wrapper, open dropdown, and wait for dropdown to render.
  const createWrapperAndOpenDropdown = async (options) => {
    createWrapper(options);
    findFilterBody().vm.$emit('dropdown-show');
    await nextTick();
  };

  // Create wrapper, open dropdown, wait for it to render, and wait for projects query to complete.
  const createWrapperAndWaitForQuery = async (options) => {
    await createWrapperAndOpenDropdown(options);
    await waitForPromises();
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('before dropdown is opened', () => {
    it('does not run the projects query', () => {
      createWrapper();

      expect(defaultProjectsRequestHandler).not.toHaveBeenCalled();
    });
  });

  describe('when dropdown is opened', () => {
    it('runs the projects query', async () => {
      await createWrapperAndOpenDropdown();

      expect(defaultProjectsRequestHandler).toHaveBeenCalledTimes(1);
      expect(defaultProjectsRequestHandler).toHaveBeenCalledWith(
        expect.objectContaining({ fullPath: groupFullPath }),
      );
    });

    it('shows the loading icon while the query is running', async () => {
      await createWrapperAndOpenDropdown();

      expect(isLoadingIconVisible()).toBe(true);
    });

    it('hides the loading icon when the query is done', async () => {
      await createWrapperAndWaitForQuery();

      expect(isLoadingIconVisible()).toBe(false);
    });

    it('does not render the loading icon when there is no next page', async () => {
      const projectsRequestHandler = getProjectsRequestHandler({ hasNextPage: false });
      await createWrapperAndOpenDropdown({ projectsRequestHandler });

      expect(findLoadingIcon().exists()).toBe(true);

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('shows an error', async () => {
      await createWrapperAndWaitForQuery({
        projectsRequestHandler: jest.fn().mockRejectedValue(new Error()),
      });

      expect(createAlert).toHaveBeenCalledTimes(1);
      expect(createAlert).toHaveBeenCalledWith({ message: PROJECT_LOADING_ERROR_MESSAGE });
    });
  });

  describe('all projects dropdown item', () => {
    it.each`
      phrase             | searchTerm | isShown
      ${'shows'}         | ${''}      | ${true}
      ${'does not show'} | ${'abc'}   | ${false}
    `(
      '$phrase the All projects dropdown item when search term is "$searchTerm"',
      async ({ searchTerm, isShown }) => {
        await createWrapperAndOpenDropdown();
        findFilterBody().vm.$emit('input', searchTerm);
        await nextTick();

        expect(findAllProjectsDropdownItem().exists()).toBe(isShown);
      },
    );
  });

  describe('searching', () => {
    it('clears the dropdown list when the search term is changed and new results are loading', async () => {
      await createWrapperAndWaitForQuery();

      expect(findProjectDropdownItems()).toHaveLength(projects.length);

      findFilterBody().vm.$emit('input', 'abc');
      await nextTick();

      expect(findProjectDropdownItems()).toHaveLength(0);
      expect(isLoadingIconVisible()).toBe(true);
    });
  });

  describe('infinite scrolling', () => {
    it('does not show the intersection observer when there is no next page', async () => {
      const projectsRequestHandler = getProjectsRequestHandler({ hasNextPage: false });
      await createWrapperAndWaitForQuery({ projectsRequestHandler });

      expect(findIntersectionObserver().exists()).toBe(false);
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('shows the intersection observer when there is a next page and the projects query is not running', async () => {
      await createWrapperAndWaitForQuery();

      expect(findIntersectionObserver().exists()).toBe(true);
      expect(isLoadingIconVisible()).toBe(false);
    });

    it('shows the loading icon and fetches the next page when the intersection observer appears', async () => {
      await createWrapperAndWaitForQuery();
      const spy = jest.spyOn(wrapper.vm.$apollo.queries.projects, 'fetchMore');
      findIntersectionObserver().vm.$emit('appear');
      await nextTick();

      expect(findProjectDropdownItems()).toHaveLength(projects.length);
      expect(findIntersectionObserver().exists()).toBe(false);
      expect(isLoadingIconVisible()).toBe(true);
      expect(spy).toHaveBeenCalledTimes(1);
      expect(defaultProjectsRequestHandler).toHaveBeenCalledTimes(2);
    });
  });
});
