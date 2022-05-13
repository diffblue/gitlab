import { GlIntersectionObserver } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import FilterBody from 'ee/security_dashboard/components/shared/filters/filter_body.vue';
import ProjectFilter from 'ee/security_dashboard/components/shared/filters/project_filter.vue';
import groupProjectsQuery from 'ee/security_dashboard/graphql/queries/group_projects.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import { projectFilter } from 'ee/security_dashboard/helpers';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

Vue.use(VueApollo);

const projects = [{ id: 1, name: 'Project 1' }];
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

describe('Project Filter component', () => {
  let wrapper;

  const createWrapper = ({ projectsRequestHandler = defaultProjectsRequestHandler } = {}) => {
    wrapper = shallowMountExtended(ProjectFilter, {
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
  const findLoadingIconFull = () => wrapper.findByTestId('loading-icon-full');
  const findLoadingIconPaging = () => wrapper.findByTestId('loading-icon-paging');

  const createWrapperAndOpenDropdown = (options) => {
    createWrapper(options);
    findFilterBody().vm.$emit('dropdown-show');
    return waitForPromises();
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
    beforeEach(() => {
      createWrapper();
      findFilterBody().vm.$emit('dropdown-show');
      return nextTick();
    });

    it('runs the projects query', async () => {
      expect(defaultProjectsRequestHandler).toHaveBeenCalledTimes(1);
      expect(defaultProjectsRequestHandler).toHaveBeenCalledWith(
        expect.objectContaining({ fullPath: groupFullPath }),
      );
    });

    it('shows the loading icon while the query is running', () => {
      expect(findLoadingIconFull().exists()).toBe(true);
    });

    it('hides the loading icon when the query is done', async () => {
      await waitForPromises();
      expect(findLoadingIconFull().exists()).toBe(false);
    });
  });

  describe('infinite scrolling', () => {
    it('does not show the intersection observer when there is no next page', async () => {
      const projectsRequestHandler = getProjectsRequestHandler({ hasNextPage: false });
      await createWrapperAndOpenDropdown({ projectsRequestHandler });

      expect(findIntersectionObserver().exists()).toBe(false);
      expect(findLoadingIconPaging().exists()).toBe(false);
    });

    it('shows the intersection observer when there is a next page and the projects query is not running', async () => {
      await createWrapperAndOpenDropdown();

      expect(findIntersectionObserver().exists()).toBe(true);
      expect(findLoadingIconPaging().exists()).toBe(false);
    });

    it('shows the loading icon and fetches the next page when the intersection observer appears', async () => {
      await createWrapperAndOpenDropdown();
      const spy = jest.spyOn(wrapper.vm.$apollo.queries.projects, 'fetchMore');
      findIntersectionObserver().vm.$emit('appear');
      await nextTick();

      expect(findIntersectionObserver().exists()).toBe(false);
      expect(findLoadingIconPaging().exists()).toBe(true);
      expect(spy).toHaveBeenCalledTimes(1);
      expect(defaultProjectsRequestHandler).toHaveBeenCalledTimes(2);
    });
  });
});
