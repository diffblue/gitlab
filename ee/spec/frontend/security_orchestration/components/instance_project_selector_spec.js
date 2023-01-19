import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import InstanceProjectSelector from 'ee/security_orchestration/components/instance_project_selector.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import getUsersProjects from '~/graphql_shared/queries/get_users_projects.query.graphql';
import ProjectSelector from '~/vue_shared/components/project_selector/project_selector.vue';

let querySpy;

const defaultProjectSelectorProps = {
  maxListHeight: 402,
  projectSearchResults: [],
  selectedProjects: [],
  showLoadingIndicator: false,
  showMinimumSearchQueryMessage: false,
  showNoResultsMessage: false,
  showSearchErrorMessage: false,
  totalResults: 0,
};

const defaultQueryVariables = {
  after: '',
  first: 20,
  membership: true,
  search: 'abc',
  searchNamespaces: true,
  sort: 'similarity',
};

const defaultPageInfo = {
  __typename: 'PageInfo',
  hasNextPage: false,
  hasPreviousPage: false,
  startCursor: null,
  endCursor: null,
};

const querySuccess = {
  data: {
    projects: {
      nodes: [
        {
          id: 'gid://gitlab/Project/5000162',
          name: 'Pages Test Again',
          nameWithNamespace: 'mixed-vulnerabilities-01 / Pages Test Again',
        },
      ],
      pageInfo: {
        __typename: 'PageInfo',
        hasNextPage: true,
        hasPreviousPage: false,
        startCursor: 'a',
        endCursor: 'z',
      },
    },
  },
};

const queryError = {
  errors: [
    {
      message: 'test',
      locations: [[{ line: 1, column: 58 }]],
      extensions: {
        value: null,
        problems: [{ path: [], explanation: 'Expected value to not be null' }],
      },
    },
  ],
};

const mockGetUsersProjects = {
  empty: { data: { projects: { nodes: [], pageInfo: defaultPageInfo } } },
  error: queryError,
  success: querySuccess,
};

const createMockApolloProvider = (queryResolver) => {
  Vue.use(VueApollo);
  return createMockApollo([[getUsersProjects, queryResolver]]);
};

describe('InstanceProjectSelector Component', () => {
  let wrapper;

  const findProjectSelector = () => wrapper.findComponent(ProjectSelector);

  const createWrapper = ({ queryResolver, propsData = {} } = {}) => {
    wrapper = shallowMountExtended(InstanceProjectSelector, {
      apolloProvider: createMockApolloProvider(queryResolver),
      propsData: {
        ...propsData,
      },
    });
  };

  describe('default', () => {
    beforeEach(() => {
      querySpy = jest.fn().mockResolvedValue(mockGetUsersProjects.success);
      createWrapper({ queryResolver: querySpy });
    });

    it('renders the project selector', () => {
      expect(findProjectSelector().props()).toStrictEqual(defaultProjectSelectorProps);
    });

    it('does not query when the search query is less than three characters', async () => {
      findProjectSelector().vm.$emit('searched', '');
      await waitForPromises();
      expect(querySpy).not.toHaveBeenCalled();
    });

    it('does query when the search query is more than three characters', async () => {
      findProjectSelector().vm.$emit('searched', 'abc');
      await waitForPromises();
      expect(querySpy).toHaveBeenCalledTimes(1);
      expect(querySpy).toHaveBeenCalledWith(defaultQueryVariables);
    });

    it('does query when the bottom is reached', async () => {
      expect(querySpy).toHaveBeenCalledTimes(0);
      findProjectSelector().vm.$emit('searched', 'abc');
      await waitForPromises();
      expect(querySpy).toHaveBeenCalledTimes(1);
      findProjectSelector().vm.$emit('bottomReached');
      await waitForPromises();
      expect(querySpy).toHaveBeenCalledTimes(2);
      expect(querySpy).toHaveBeenCalledWith({
        ...defaultQueryVariables,
        after: 'z',
      });
    });

    it('emits on "projectClicked"', () => {
      const project = { id: 0, name: 'test' };
      findProjectSelector().vm.$emit('projectClicked', project);
      expect(wrapper.emitted('projectClicked')).toStrictEqual([[project]]);
    });
  });

  describe('other states', () => {
    it('notifies project selector of search error', async () => {
      querySpy = jest.fn().mockResolvedValue(mockGetUsersProjects.error);
      createWrapper({ queryResolver: querySpy });
      await nextTick();
      findProjectSelector().vm.$emit('searched', 'abc');
      await waitForPromises();
      expect(findProjectSelector().props()).toStrictEqual({
        ...defaultProjectSelectorProps,
        showSearchErrorMessage: true,
      });
    });

    it('notifies project selector of no results', async () => {
      querySpy = jest.fn().mockResolvedValue(mockGetUsersProjects.empty);
      createWrapper({ queryResolver: querySpy });
      await nextTick();
      findProjectSelector().vm.$emit('searched', 'abc');
      await waitForPromises();
      expect(findProjectSelector().props()).toStrictEqual({
        ...defaultProjectSelectorProps,
        showNoResultsMessage: true,
      });
    });
  });
});
