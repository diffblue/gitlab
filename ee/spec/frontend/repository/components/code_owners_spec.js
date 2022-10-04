import { GlLink, GlButton } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CodeOwners from 'ee_component/vue_shared/components/code_owners/code_owners.vue';
import codeOwnersInfoQuery from 'ee/graphql_shared/queries/code_owners_info.query.graphql';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { codeOwnerMock, codeOwnersMultipleMock, codeOwnersDataMock, refMock } from '../mock_data';

let wrapper;
let mockResolver;

const createComponent = async (codeOwners = [codeOwnerMock], mountFn = shallowMount) => {
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
    mountFn(CodeOwners, {
      apolloProvider: createMockApollo([[codeOwnersInfoQuery, mockResolver]]),
      propsData: { projectPath: 'some/project', filePath: 'some/file' },
      mixins: [{ data: () => ({ ref: refMock }) }],
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
  const findToggle = () => wrapper.findComponent(GlButton);
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

  it('doesn`t render toggle when the number of codeowners is less than 5', () => {
    expect(findToggle().exists()).toBe(false);
  });

  it.each`
    codeOwners                            | commaSeparators | codeOwnersLength
    ${[]}                                 | ${0}            | ${0}
    ${[codeOwnerMock]}                    | ${0}            | ${1}
    ${codeOwnersMultipleMock.slice(0, 2)} | ${1}            | ${2}
    ${codeOwnersMultipleMock.slice(0, 3)} | ${2}            | ${3}
    ${codeOwnersMultipleMock}             | ${4}            | ${5}
  `('matches the snapshot', async ({ codeOwners, commaSeparators, codeOwnersLength }) => {
    await createComponent(codeOwners);

    expect(findCommaSeparators().length).toBe(commaSeparators);
    expect(findCodeOwners().length).toBe(codeOwnersLength);
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('when the number of code owners is more than 5', () => {
    beforeEach(() => createComponent(codeOwnersMultipleMock, mount));

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
