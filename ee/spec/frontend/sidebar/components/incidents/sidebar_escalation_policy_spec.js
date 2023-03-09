import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import SidebarEscalationPolicy from 'ee/sidebar/components/incidents/sidebar_escalation_policy.vue';
import policiesQuery from 'ee/sidebar/queries/project_escalation_policies.query.graphql';
import currentPolicyQuery from 'ee/sidebar/queries/issue_escalation_policy.query.graphql';
import { clickEdit } from '../../helpers';
import {
  mockEscalationPolicy1,
  mockEscalationPolicy2,
  mockEscalationPoliciesResponse,
  mockCurrentEscalationPolicyResponse,
  mockNullEscalationPolicyResponse,
} from './mock_data';

Vue.use(VueApollo);

describe('Sidebar Escalation Policy Widget', () => {
  let wrapper;
  let mockApollo;
  let propsData;
  let provide;
  let escalationPolicyResponse;

  const createComponent = async () => {
    mockApollo = createMockApollo([
      [currentPolicyQuery, jest.fn().mockResolvedValue(escalationPolicyResponse)],
      [policiesQuery, jest.fn().mockResolvedValue(mockEscalationPoliciesResponse)],
    ]);

    wrapper = extendedWrapper(
      mount(SidebarEscalationPolicy, {
        apolloProvider: mockApollo,
        propsData,
        provide,
      }),
    );

    await waitForPromises();
  };

  beforeEach(() => {
    propsData = {
      projectPath: 'gitlab-test/test',
      iid: '1',
      escalationsPossible: true,
    };

    provide = {
      canUpdate: true,
      isClassicSidebar: true,
    };

    escalationPolicyResponse = mockCurrentEscalationPolicyResponse;
  });

  afterEach(() => {
    mockApollo = null;
    propsData = null;
    provide = null;
    escalationPolicyResponse = null;
  });

  const findNarrowSidebarPolicy = () => wrapper.findByTestId('sidebar-collapsed-attribute-title');
  const findExpandedSidebarPolicy = () => wrapper.findByTestId('select-escalation-policy');
  const findMobileIcon = () => wrapper.findByTestId('mobile-icon');
  const findPolicyLink = () => wrapper.find('[href="/gitlab-test/test/-/escalation_policies"]');
  const findHelpLink = () =>
    wrapper.find('[href="/help/operations/incident_management/escalation_policies.md"]');

  const verifyMobileIcon = () => {
    it('renders the mobile icon', async () => {
      await createComponent();

      expect(findMobileIcon().exists()).toBe(true);
      expect(findMobileIcon().classes('hide-collapsed')).toBe(false);
    });
  };
  const verifyNarrowSidebarPolicyText = (text) => {
    it(`renders '${text}' to describe the policy`, async () => {
      await createComponent();

      expect(findNarrowSidebarPolicy().text()).toBe(text);
      expect(findNarrowSidebarPolicy().classes('hide-collapsed')).toBe(false);
    });
  };
  const verifyExpandedSidebarPolicyText = (text) => {
    it(`renders '${text}' to describe the policy`, async () => {
      await createComponent();

      expect(findExpandedSidebarPolicy().text()).toBe(text);
      expect(findExpandedSidebarPolicy().classes('hide-collapsed')).toBe(true);
      expect(findExpandedSidebarPolicy().isVisible()).toBe(true);
    });
  };
  const verifyEmptyPolicyContent = () => {
    describe('when the policy is not set', () => {
      beforeEach(() => {
        escalationPolicyResponse = mockNullEscalationPolicyResponse;
      });

      verifyMobileIcon();
      verifyExpandedSidebarPolicyText('None');
      verifyNarrowSidebarPolicyText('None');
    });
  };
  const verifyPopulatedPolicyContent = () => {
    describe('when the policy is initially set', () => {
      verifyMobileIcon();
      verifyExpandedSidebarPolicyText(mockEscalationPolicy1.title);
      verifyNarrowSidebarPolicyText('Paged');

      it('links to the escalation policies for the project', async () => {
        await createComponent();

        expect(findPolicyLink().exists()).toBe(true);
      });
    });
  };

  describe('when user has permissions to update policy', () => {
    verifyEmptyPolicyContent();
    verifyPopulatedPolicyContent();

    it('renders list of escalation policies in the dropdown', async () => {
      await createComponent();
      await clickEdit(wrapper);
      jest.runOnlyPendingTimers();
      await waitForPromises();

      const dropdownItems = wrapper.findAllByTestId('escalation-policy-items');

      expect(dropdownItems.at(0).text()).toBe(mockEscalationPolicy1.title);
      expect(dropdownItems.at(1).text()).toBe(mockEscalationPolicy2.title);
    });

    describe('when a policy is selected', () => {
      beforeEach(async () => {
        await createComponent();
        await clickEdit(wrapper);
        jest.runOnlyPendingTimers();
        await waitForPromises();
        await wrapper.findByTestId('escalation-policy-items').trigger('click');
      });

      verifyPopulatedPolicyContent();
    });
  });

  describe('when user does not have permissions to update policy', () => {
    beforeEach(() => {
      provide.canUpdate = false;
    });

    verifyEmptyPolicyContent();
    verifyPopulatedPolicyContent();
  });

  describe('when escalation policies are not available for the project', () => {
    beforeEach(() => {
      propsData.escalationsPossible = false;
    });

    verifyEmptyPolicyContent();

    it('can be opened and closed', async () => {
      await createComponent();
      await wrapper.find('[data-testid="help-button"]').trigger('click');

      expect(findHelpLink().exists()).toBe(true);

      await wrapper.find('[data-testid="close-help-button"]').trigger('click');

      expect(findHelpLink().exists()).toBe(false);
    });
  });
});
