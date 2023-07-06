import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapse, GlBadge, GlPopover, GlLink } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CodeOwners, {
  i18n,
  codeOwnersHelpPath,
} from 'ee_component/vue_shared/components/code_owners/code_owners.vue';
import codeOwnersInfoQuery from 'ee/graphql_shared/queries/code_owners_info.query.graphql';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { codeOwnersPath, codeOwnersMock, codeOwnersPropsMock } from '../mock_data';

let wrapper;
let mockResolver;

const createComponent = async ({ props = {}, codeOwnersDataMock = codeOwnersMock } = {}) => {
  Vue.use(VueApollo);

  const project = {
    id: '1234',
    repository: {
      codeOwnersPath,
      blobs: {
        nodes: [{ id: '345', codeOwners: codeOwnersDataMock }],
      },
    },
  };

  mockResolver = jest.fn().mockResolvedValue({ data: { project } });

  wrapper = extendedWrapper(
    shallowMount(CodeOwners, {
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
  const findCodeOwners = () => wrapper.findAllByTestId('code-owners');
  const findCommaSeparators = () => wrapper.findAllByTestId('comma-separator');
  const findAndSeparators = () => wrapper.findAllByTestId('and-separator');
  const findCollapse = () => wrapper.findComponent(GlCollapse);
  const findToggle = () => wrapper.findByTestId('collapse-toggle');
  const findBranchRulesLink = () => wrapper.findByTestId('branch-rules-link');
  const findLinkToFile = () => wrapper.findByTestId('codeowners-file-link');
  const findLinkToDocs = () => wrapper.findByTestId('codeowners-docs-link');
  const findNoCodeownersText = () => wrapper.findByTestId('no-codeowners-text');
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findHelpPopoverTrigger = () => wrapper.findByTestId('help-popover-trigger');
  const findHelpPopover = () => wrapper.findComponent(GlPopover);
  const findHelpPopoverLink = () => findHelpPopover().findComponent(GlLink);

  beforeEach(() => createComponent());

  describe('Default state', () => {
    it('renders a link to CODEOWNERS file', () => {
      expect(findLinkToFile().attributes('href')).toBe(codeOwnersPath);
    });

    it('renders a Badge with a Number of codeowners', () => {
      expect(findBadge().text()).toBe(`${codeOwnersMock.length}`);
    });

    it('renders a toggle button with correct text', () => {
      expect(findToggle().exists()).toBe(true);
      expect(findToggle().text()).toBe(i18n.showAll);
    });

    it('expands when you click on a toggle', async () => {
      await findToggle().vm.$emit('click');
      await nextTick();
      expect(findCollapse().attributes('visible')).toBe('true');
      expect(findToggle().text()).toBe(i18n.hideAll);
    });

    it('renders codeowners list', () => {
      expect(findCodeOwners().length).toBe(codeOwnersMock.length);
    });

    it('renders a popover trigger with question icon', () => {
      expect(findHelpPopoverTrigger().props('icon')).toBe('question-o');
      expect(findHelpPopoverTrigger().attributes('aria-label')).toBe(i18n.helpText);
    });

    it('renders a popover', () => {
      expect(findHelpPopoverTrigger().attributes('id')).toBe(findHelpPopover().props('target'));
      expect(findHelpPopover().props()).toMatchObject({
        placement: 'top',
        triggers: 'hover focus',
      });
      expect(findHelpPopoverLink().exists()).toBe(true);
      expect(findHelpPopover().text()).toContain(i18n.helpText);
    });
  });

  describe('when no codeowners', () => {
    beforeEach(() => createComponent({ codeOwnersDataMock: [] }));

    it('renders no codeowners text', () => {
      expect(findNoCodeownersText().text()).toBe(i18n.noCodeOwnersText);
    });

    it('renders a link to docs page', () => {
      expect(findLinkToDocs().attributes('href')).toBe(codeOwnersHelpPath);
      expect(findLinkToDocs().attributes('target')).toBe('_blank');
    });

    it('does not render a popover trigger', () => {
      expect(findHelpPopoverTrigger().exists()).toBe(false);
    });

    it('does not render a popover', () => {
      expect(findHelpPopover().exists()).toBe(false);
    });
  });

  describe('link to branch settings', () => {
    it('does not render a link to branch rules settings for non-maintainers', async () => {
      await createComponent({ props: { canViewBranchRules: false } });
      expect(findBranchRulesLink().exists()).toBe(false);
    });

    it('renders a link to branch rules settings for users with maintainer access and higher', () => {
      expect(findBranchRulesLink().attributes('href')).toBe(codeOwnersPropsMock.branchRulesPath);
    });
  });

  it.each`
    codeOwners                    | commaSeparators | codeOwnersLength | andSeparators
    ${[]}                         | ${0}            | ${0}             | ${0}
    ${codeOwnersMock.slice(0, 1)} | ${0}            | ${1}             | ${0}
    ${codeOwnersMock.slice(0, 2)} | ${0}            | ${2}             | ${1}
    ${codeOwnersMock.slice(0, 3)} | ${1}            | ${3}             | ${1}
    ${codeOwnersMock}             | ${5}            | ${7}             | ${1}
  `(
    'renders "$commaSeparators" comma separators, "$andSeparators" and separators for "$codeOwnersLength" codeowners',
    async ({ codeOwners, commaSeparators, codeOwnersLength, andSeparators }) => {
      await createComponent({ codeOwnersDataMock: codeOwners });
      expect(findCommaSeparators().length).toBe(commaSeparators);
      expect(findAndSeparators().length).toBe(andSeparators);
      expect(findCodeOwners().length).toBe(codeOwnersLength);
    },
  );
});
