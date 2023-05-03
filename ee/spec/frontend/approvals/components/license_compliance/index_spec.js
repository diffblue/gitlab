import { GlIcon, GlSkeletonLoader } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import LicenseComplianceApprovals from 'ee/approvals/components/license_compliance/index.vue';
import approvalsLicenceComplianceModule, {
  APPROVALS,
  APPROVALS_MODAL,
} from 'ee/approvals/stores/modules/license_compliance';
import modalModule from '~/vuex_shared/modules/modal';

Vue.use(Vuex);

const TEST_APPROVALS_DOCUMENTATION_PATH = 'http://foo.bar';
const TEST_LOCKED_APPROVALS_RULE_NAME = 'License-Check';

describe('EE Approvals LicenseCompliance', () => {
  let wrapper;
  let store;

  const createStore = () => {
    store = {
      state: {
        settings: {
          approvalsDocumentationPath: TEST_APPROVALS_DOCUMENTATION_PATH,
          lockedApprovalsRuleName: TEST_LOCKED_APPROVALS_RULE_NAME,
        },
      },
      modules: {
        [APPROVALS]: approvalsLicenceComplianceModule(),
        [APPROVALS_MODAL]: modalModule(),
      },
    };
  };

  const createWrapper = () => {
    wrapper = mount(LicenseComplianceApprovals, {
      store: new Vuex.Store(store),
      stubs: {
        'rule-form': true,
      },
    });
  };

  beforeEach(() => {
    createStore();

    jest.spyOn(store.modules.approvals.actions, 'fetchRules').mockImplementation();
    jest.spyOn(store.modules.approvalsModal.actions, 'open');
  });

  const findByHrefAttribute = (href) => wrapper.find(`[href="${href}"]`);
  const findOpenModalButton = () => wrapper.find('button');
  const findLoadingIndicator = () => wrapper.findComponent(GlSkeletonLoader);
  const findInformationIcon = () => wrapper.findComponent(GlIcon);
  const findLicenseCheckStatus = () => wrapper.find('[data-testid="licenseCheckStatus"]');

  describe('when created', () => {
    it('fetches approval rules', () => {
      expect(store.modules.approvals.actions.fetchRules).not.toHaveBeenCalled();

      createWrapper();

      expect(store.modules.approvals.actions.fetchRules).toHaveBeenCalledTimes(1);
    });
  });

  describe('when loading', () => {
    beforeEach(() => {
      store.modules.approvals.state.isLoading = true;

      createWrapper();
    });

    it('renders the open-modal button with an active loading state', () => {
      expect(findOpenModalButton().props('loading')).toBe(true);
    });

    it('disables the open-modal button', () => {
      expect(findOpenModalButton().attributes('disabled')).toBeDefined();
    });

    it('renders a loading indicator', () => {
      expect(findLoadingIndicator().exists()).toBe(true);
    });
  });

  describe('when data has loaded', () => {
    const mockLicenseCheckRule = { name: TEST_LOCKED_APPROVALS_RULE_NAME };

    beforeEach(() => {
      store.modules.approvals.state.rules = [mockLicenseCheckRule];

      createWrapper();
    });

    it('renders the open-modal button without an active loading state', () => {
      expect(findOpenModalButton().props('loading')).toBe(false);
    });

    it('does not render a loading indicator', () => {
      expect(findLoadingIndicator().exists()).toBe(false);
    });

    it('renders an information icon', () => {
      expect(findInformationIcon().props('name')).toBe('information-o');
    });

    it('opens the link to the documentation page in a new tab', () => {
      expect(findByHrefAttribute(TEST_APPROVALS_DOCUMENTATION_PATH).attributes('target')).toBe(
        '_blank',
      );
    });

    it('opens a modal when the open-modal button is clicked', () => {
      expect(store.modules.approvalsModal.actions.open).not.toHaveBeenCalled();

      findOpenModalButton().trigger('click');

      expect(store.modules.approvalsModal.actions.open).toHaveBeenCalledWith(
        expect.any(Object),
        mockLicenseCheckRule,
      );
    });
  });

  describe.each`
    givenApprovalRule                                                  | expectedStatus
    ${{}}                                                              | ${'inactive'}
    ${{ name: 'Foo', approvalsRequired: 0 }}                           | ${'inactive'}
    ${{ name: 'Foo', approvalsRequired: 1 }}                           | ${'inactive'}
    ${{ name: TEST_LOCKED_APPROVALS_RULE_NAME, approvalsRequired: 0 }} | ${'inactive'}
    ${{ name: TEST_LOCKED_APPROVALS_RULE_NAME, approvalsRequired: 1 }} | ${'active'}
  `('when approval rule is "$givenApprovalRule.name"', ({ givenApprovalRule, expectedStatus }) => {
    beforeEach(() => {
      store.modules.approvals.state.rules = [givenApprovalRule];

      createWrapper();
    });

    it(`renders the status as "${expectedStatus}"`, () => {
      expect(findLicenseCheckStatus().text()).toBe(`License Approvals are ${expectedStatus}`);
    });
  });
});
