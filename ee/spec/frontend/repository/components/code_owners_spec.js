import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CodeOwners from 'ee_component/repository/components/code_owners.vue';
import codeOwnersInfoQuery from 'ee/repository/queries/code_owners_info.query.graphql';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { codeOwnerMock, codeOwnersDataMock, refMock } from '../mock_data';

let wrapper;
let mockResolver;

const createComponent = async (codeOwners = [codeOwnerMock]) => {
  Vue.use(VueApollo);

  const project = {
    ...codeOwnersDataMock,
    repository: {
      blobs: {
        nodes: [{ id: '345', codeOwners }],
      },
    },
  };

  mockResolver = jest.fn().mockResolvedValue({ data: { project } });

  wrapper = extendedWrapper(
    shallowMount(CodeOwners, {
      apolloProvider: createMockApollo([[codeOwnersInfoQuery, mockResolver]]),
      propsData: { projectPath: 'some/project', filePath: 'some/file' },
      mixins: [{ data: () => ({ ref: refMock }) }],
    }),
  );

  // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
  // eslint-disable-next-line no-restricted-syntax
  wrapper.setData({ isFetching: false });

  await waitForPromises();
};

describe('Code owners component', () => {
  const findHelpIcon = () => wrapper.findByTestId('help-icon');
  const findUsersIcon = () => wrapper.findByTestId('users-icon');
  const findCodeOwners = () => wrapper.findAllByTestId('code-owners');
  const findCommaSeparators = () => wrapper.findAllByTestId('comma-separator');
  const findAndSeparator = () => wrapper.findAllByTestId('and-separator');
  const findLink = () => wrapper.findComponent(GlLink);

  beforeEach(() => createComponent());

  afterEach(() => wrapper.destroy());

  describe('help link', () => {
    it('renders a GlLink component', () => {
      expect(findLink().exists()).toBe(true);
      expect(findLink().attributes('href')).toBe('/help/user/project/code_owners');
      expect(findLink().attributes('target')).toBe('_blank');
      expect(findLink().attributes('title')).toBe('About this feature');
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

  it.each`
    codeOwners                                       | commaSeparators | hasAndSeparator
    ${[]}                                            | ${0}            | ${false}
    ${[codeOwnerMock]}                               | ${0}            | ${false}
    ${[codeOwnerMock, codeOwnerMock]}                | ${0}            | ${true}
    ${[codeOwnerMock, codeOwnerMock, codeOwnerMock]} | ${2}            | ${true}
  `('matches the snapshot', async ({ codeOwners, commaSeparators, hasAndSeparator }) => {
    await createComponent(codeOwners);

    expect(findCommaSeparators().length).toBe(commaSeparators);
    expect(findAndSeparator().exists()).toBe(hasAndSeparator);
    expect(findCodeOwners().length).toBe(codeOwners.length);
    expect(wrapper.element).toMatchSnapshot();
  });
});
