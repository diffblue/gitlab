import { shallowMount, mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CodeOwners from 'ee_component/vue_shared/components/code_owners/code_owners.vue';
import codeOwnersInfoQuery from 'ee/graphql_shared/queries/code_owners_info.query.graphql';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import {
  codeOwnersPath,
  codeOwnerMock,
  codeOwnersMultipleMock,
  codeOwnersPropsMock,
} from '../mock_data';

let wrapper;
let mockResolver;

const createComponent = async ({
  mountFn = shallowMount,
  props = {},
  codeOwnerDataMock = [codeOwnerMock],
} = {}) => {
  Vue.use(VueApollo);

  const project = {
    id: '1234',
    repository: {
      codeOwnersPath,
      blobs: {
        nodes: [{ id: '345', codeOwners: codeOwnerDataMock }],
      },
    },
  };

  mockResolver = jest.fn().mockResolvedValue({ data: { project } });

  wrapper = extendedWrapper(
    mountFn(CodeOwners, {
      apolloProvider: createMockApollo([[codeOwnersInfoQuery, mockResolver]]),
      propsData: {
        ...codeOwnersPropsMock,
        ...props,
      },
    }),
  );

  await waitForPromises();
};

describe('Code owners component', () => {
  const findHelpIcon = () => wrapper.findByTestId('help-icon');
  const findUsersIcon = () => wrapper.findByTestId('users-icon');
  const findCodeOwners = () => wrapper.findAllByTestId('code-owners');
  const findCommaSeparators = () => wrapper.findAllByTestId('comma-separator');
  const findAndSeparators = () => wrapper.findAllByTestId('and-separator');
  const findToggle = () => wrapper.findByTestId('collapse-toggle');
  const findBranchRulesLink = () => wrapper.findByTestId('branch-rules-link');
  const findLinkToFile = () => wrapper.findByTestId('codeowners-file-link');
  const findLinkToDocs = () => wrapper.findByTestId('codeowners-docs-link');

  beforeEach(() => createComponent());

  describe('help link', () => {
    it('renders a link to CODEOWNERS file', () => {
      expect(findLinkToFile().attributes('href')).toBe(codeOwnersPath);
    });

    it('renders a link to docs component', () => {
      expect(findLinkToDocs().attributes('href')).toBe('/help/user/project/code_owners');
      expect(findLinkToDocs().attributes('target')).toBe('_blank');
      expect(findLinkToDocs().attributes('title')).toBe('About this feature');
    });

    it('renders a Help icon', () => {
      expect(findHelpIcon().exists()).toBe(true);
      expect(findHelpIcon().props('name')).toBe('question-o');
    });
  });

  it('renders a Users icon', () => {
    expect(findUsersIcon().exists()).toBe(true);
    expect(findUsersIcon().props('name')).toBe('users');
  });

  it('doesn`t render toggle when the number of codeowners is less than 5', () => {
    expect(findToggle().exists()).toBe(false);
  });

  it('does not render a link to branch rules settings for non-maintainers', async () => {
    await createComponent({ props: { canViewBranchRules: false } });
    expect(findBranchRulesLink().exists()).toBe(false);
  });

  it('renders a link to branch rules settings for users with maintainer access and higher', () => {
    expect(findBranchRulesLink().attributes('href')).toBe(codeOwnersPropsMock.branchRulesPath);
  });

  it.each`
    codeOwners                            | commaSeparators | codeOwnersLength
    ${[]}                                 | ${0}            | ${0}
    ${[codeOwnerMock]}                    | ${0}            | ${1}
    ${codeOwnersMultipleMock.slice(0, 2)} | ${1}            | ${2}
    ${codeOwnersMultipleMock.slice(0, 3)} | ${2}            | ${3}
    ${codeOwnersMultipleMock}             | ${4}            | ${5}
  `('matches the snapshot', async ({ codeOwners, commaSeparators, codeOwnersLength }) => {
    await createComponent({ codeOwnerDataMock: codeOwners });

    expect(findCommaSeparators().length).toBe(commaSeparators);
    expect(findCodeOwners().length).toBe(codeOwnersLength);
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('when the number of code owners is more than 5', () => {
    beforeEach(() =>
      createComponent({ codeOwnerDataMock: codeOwnersMultipleMock, mountFn: mount }),
    );

    it('renders a toggle button with correct text', () => {
      expect(findToggle().exists()).toBe(true);
      expect(findToggle().text()).toBe('2 more');
    });

    it('renders only first 5 codeowners at initial state', () => {
      expect(findCodeOwners().length).toBe(5);
    });

    it('expands when you click on a toggle', async () => {
      await findToggle().trigger('click');
      await nextTick();
      expect(findCodeOwners().length).toBe(codeOwnersMultipleMock.length);
      expect(findToggle().text()).toBe('show less');
      expect(findAndSeparators().length).toBe(1);
    });
  });
});
