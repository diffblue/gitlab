import Vue, { nextTick } from 'vue';
import { GlCollapsibleListbox } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import InstanceProjectSelector from 'ee/security_orchestration/components/policies/instance_project_selector.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import getUsersProjects from '~/graphql_shared/queries/get_users_projects.query.graphql';

let querySpy;

const defaultProjectSelectorProps = {
  disabled: false,
  items: [],
  selected: '',
  toggleText: 'Select a project',
  noResultsText: 'Enter at least three characters to search',
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

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findErrorMessage = () => wrapper.findByTestId('error-message');

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
      expect(findListbox().props()).toMatchObject(defaultProjectSelectorProps);
    });

    it('renders custom header', () => {
      createWrapper({ propsData: { headerText: 'Test header' } });
      expect(findListbox().props('headerText')).toBe('Test header');
    });

    it('does not query when the search query is less than three characters', async () => {
      findListbox().vm.$emit('searched', '');
      await waitForPromises();
      expect(querySpy).not.toHaveBeenCalled();
    });

    it('does query when the search query is more than three characters', async () => {
      findListbox().vm.$emit('search', 'abc');
      await waitForPromises();
      expect(querySpy).toHaveBeenCalledTimes(1);
      expect(querySpy).toHaveBeenCalledWith(defaultQueryVariables);
    });

    it('does query when the bottom is reached', async () => {
      expect(querySpy).toHaveBeenCalledTimes(0);
      findListbox().vm.$emit('search', 'abc');
      await waitForPromises();
      expect(querySpy).toHaveBeenCalledTimes(1);
      findListbox().vm.$emit('bottom-reached');
      await waitForPromises();
      expect(querySpy).toHaveBeenCalledTimes(2);
      expect(querySpy).toHaveBeenCalledWith({
        ...defaultQueryVariables,
        after: 'z',
      });
    });

    it('emits on "projectClicked"', async () => {
      findListbox().vm.$emit('search', 'Pages');
      await waitForPromises();

      const project = { id: 'gid://gitlab/Project/5000162' };
      findListbox().vm.$emit('select', project.id);
      expect(wrapper.emitted('projectClicked')).toStrictEqual([
        [mockGetUsersProjects.success.data.projects.nodes[0]],
      ]);
    });
  });

  describe('other states', () => {
    it('notifies project selector of search error', async () => {
      querySpy = jest.fn().mockResolvedValue(mockGetUsersProjects.error);
      createWrapper({ queryResolver: querySpy });
      await nextTick();
      findListbox().vm.$emit('search', 'abc');
      await waitForPromises();
      expect(findErrorMessage().exists()).toBe(true);
      expect(findListbox().props()).toMatchObject({
        ...defaultProjectSelectorProps,
        noResultsText: 'Sorry, no projects matched your search',
      });
    });

    it('notifies project selector of no results', async () => {
      querySpy = jest.fn().mockResolvedValue(mockGetUsersProjects.empty);
      createWrapper({ queryResolver: querySpy });
      await nextTick();
      findListbox().vm.$emit('search', 'abc');
      await waitForPromises();
      expect(findErrorMessage().exists()).toBe(false);
      expect(findListbox().props()).toMatchObject({
        ...defaultProjectSelectorProps,
        noResultsText: 'Sorry, no projects matched your search',
      });
    });
  });
});
