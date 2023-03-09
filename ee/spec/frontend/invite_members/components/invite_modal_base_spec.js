import { GlModal, GlSprintf } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContentTransition from '~/vue_shared/components/content_transition.vue';
import CEInviteModalBase from '~/invite_members/components/invite_modal_base.vue';
import EEInviteModalBase from 'ee/invite_members/components/invite_modal_base.vue';
import {
  OVERAGE_MODAL_TITLE,
  OVERAGE_MODAL_CONTINUE_BUTTON,
  OVERAGE_MODAL_BACK_BUTTON,
} from 'ee/invite_members/constants';
import { propsData as propsDataCE } from 'jest/invite_members/mock_data/modal_base';
import getReconciliationStatus from 'ee/invite_members/subscription_eligible.customer.query.graphql';
import getBillableUserCountChanges from 'ee/invite_members/billable_users_count.query.graphql';
import { createMockClient } from 'helpers/mock_apollo_helper';

Vue.use(VueApollo);

const generateReconciliationResponse = (isEligible) => {
  return jest
    .fn()
    .mockResolvedValue({ data: { reconciliation: { eligibleForSeatReconciliation: isEligible } } });
};

describe('EEInviteModalBase', () => {
  let wrapper;
  let listenerSpy;
  let mockApollo;

  const defaultResolverMock = generateReconciliationResponse(true);
  const defaultBillableMock = jest.fn().mockResolvedValue({
    data: {
      group: {
        id: 12345,
        gitlabSubscriptionsPreviewBillableUserChange: {
          willIncreaseOverage: true,
          newBillableUserCount: 2,
          seatsInSubscription: 1,
        },
      },
    },
  });

  const createComponent = ({
    props = {},
    glFeatures = {},
    queryHandler = defaultResolverMock,
  } = {}) => {
    const mockCustomersDotClient = createMockClient([[getReconciliationStatus, queryHandler]]);
    const mockGitlabClient = createMockClient([[getBillableUserCountChanges, defaultBillableMock]]);
    mockApollo = new VueApollo({
      defaultClient: mockCustomersDotClient,
      clients: { customersDotClient: mockCustomersDotClient, gitlabClient: mockGitlabClient },
    });

    wrapper = shallowMountExtended(EEInviteModalBase, {
      propsData: {
        ...propsDataCE,
        ...props,
      },
      apolloProvider: mockApollo,
      provide: {
        glFeatures,
      },
      attrs: {
        'access-levels': propsDataCE.accessLevels,
      },
      stubs: {
        GlSprintf,
        InviteModalBase: CEInviteModalBase,
        ContentTransition,
        GlModal: stubComponent(GlModal, {
          template:
            '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-footer"></slot></div>',
        }),
      },
      listeners: {
        submit: (...args) => listenerSpy('submit', ...args),
        reset: (...args) => listenerSpy('reset', ...args),
        foo: (...args) => listenerSpy('foo', ...args),
      },
    });
  };

  beforeEach(() => {
    listenerSpy = jest.fn();
  });

  const findCEBase = () => wrapper.findComponent(CEInviteModalBase);
  const findModal = () => wrapper.findComponent(GlModal);
  const findInitialModalContent = () => wrapper.findByTestId('invite-modal-initial-content');
  const findOverageModalContent = () => wrapper.findByTestId('invite-modal-overage-content');
  const findModalTitle = () => findModal().props('title');
  const findActionButton = () => wrapper.findByTestId('invite-modal-submit');
  const findCancelButton = () => wrapper.findByTestId('invite-modal-cancel');

  const emitClickFromModal = (findButton) => () =>
    findButton().vm.$emit('click', { preventDefault: jest.fn() });

  const clickInviteButton = emitClickFromModal(findActionButton);
  const clickBackButton = emitClickFromModal(findCancelButton);

  describe('default', () => {
    beforeEach(() => {
      createComponent({ props: { invalidFeedbackMessage: 'error appeared', fullPath: 'project' } });
    });

    it('passes attrs to CE base', () => {
      expect(findCEBase().props()).toMatchObject({
        ...propsDataCE,
        currentSlot: 'default',
        extraSlots: EEInviteModalBase.EXTRA_SLOTS,
        invalidFeedbackMessage: 'error appeared',
      });
    });

    it("doesn't show the overage content", () => {
      expect(findOverageModalContent().isVisible()).toBe(false);
    });

    it('when reset is emitted on base, emits reset', () => {
      expect(wrapper.emitted('reset')).toBeUndefined();

      findCEBase().vm.$emit('reset');

      expect(wrapper.emitted('reset')).toHaveLength(1);
    });

    it("doesn't call api on initial render", () => {
      expect(defaultResolverMock).toHaveBeenCalledTimes(0);
    });

    describe('(integration) when invite is clicked', () => {
      beforeEach(async () => {
        clickInviteButton();
        await nextTick();
        await waitForPromises();
      });

      it('does not change title', () => {
        expect(findModalTitle()).toBe(propsDataCE.modalTitle);
      });

      it('shows initial modal content', () => {
        expect(findInitialModalContent().isVisible()).toBe(true);
      });

      it('emits submit', () => {
        expect(wrapper.emitted('submit')).toEqual([[{ accessLevel: 10, expiresAt: undefined }]]);
      });
    });
  });

  describe('with overageMembersModal feature flag and a group to invite, and invite is clicked', () => {
    beforeEach(async () => {
      createComponent({
        props: { newGroupToInvite: 123, rootGroupId: '54321', fullPath: 'project' },
        glFeatures: { overageMembersModal: true },
      });
      clickInviteButton();
      await nextTick();
      await waitForPromises();
    });

    it('calls graphql API and passes correct parameters', () => {
      expect(defaultResolverMock).toHaveBeenCalledTimes(1);
      expect(defaultResolverMock).toHaveBeenCalledWith({ namespaceId: 54321 });
    });
  });

  describe('with overageMembersModal feature flag, and invite is clicked', () => {
    beforeEach(async () => {
      createComponent({
        props: { newUsersToInvite: [123], fullPath: 'project' },
        glFeatures: { overageMembersModal: true },
      });
      clickInviteButton();
      await waitForPromises();
    });

    it('does not emit submit', () => {
      expect(wrapper.emitted().submit).toBeUndefined();
    });

    it('renders the modal with the correct title', () => {
      expect(findModalTitle()).toBe(OVERAGE_MODAL_TITLE);
    });

    it('renders the Back button text correctly', () => {
      const actionButton = findActionButton();

      expect(actionButton.text()).toBe(OVERAGE_MODAL_CONTINUE_BUTTON);
      expect(actionButton.attributes('data-qa-selector')).toBe('invite_button');

      expect(actionButton.props()).toMatchObject({
        variant: 'confirm',
        disabled: false,
        loading: false,
      });
    });

    it('renders the Continue button text correctly', () => {
      expect(findCancelButton().text()).toBe(OVERAGE_MODAL_BACK_BUTTON);
    });

    it('shows the info text', () => {
      expect(findModal().text()).toContain(
        'Your subscription includes 1 seat. If you continue, the _name_ group will have 2 seats in use and will be billed for the overage.',
      );
    });

    it('does not show the initial modal content', () => {
      expect(findInitialModalContent().isVisible()).toBe(false);
    });

    describe('when switches back to the initial modal', () => {
      beforeEach(() => clickBackButton());

      it('shows the initial modal', () => {
        expect(findModal().props('title')).toBe(propsDataCE.modalTitle);
        expect(findInitialModalContent().isVisible()).toBe(true);
      });

      it("doesn't show the overage content", () => {
        expect(findOverageModalContent().isVisible()).toBe(false);
      });
    });
  });

  describe('when the group is not eligible to show overage', () => {
    beforeEach(async () => {
      createComponent({
        props: { fullPath: 'project' },
        glFeatures: { overageMembersModal: true },
        queryHandler: generateReconciliationResponse(false),
      });

      clickInviteButton();
      await nextTick();
    });

    it('shows the initial modal', () => {
      expect(findModal().props('title')).toBe(propsDataCE.modalTitle);
      expect(findInitialModalContent().isVisible()).toBe(true);
    });

    it("doesn't show the overage content", () => {
      expect(findOverageModalContent().isVisible()).toBe(false);
    });
  });

  describe('when group eligibility API request fails', () => {
    beforeEach(async () => {
      createComponent({
        props: { fullPath: 'project' },
        glFeatures: { overageMembersModal: true },
        queryHandler: jest.fn().mockRejectedValue(new Error('GraphQL error')),
      });

      clickInviteButton();
      await nextTick();
      await waitForPromises();
    });

    it('emits submit event', () => {
      expect(wrapper.emitted('submit')).toHaveLength(1);
      expect(wrapper.emitted('submit')).toEqual([[{ accessLevel: 10, expiresAt: undefined }]]);
    });

    it('shows the initial modal', () => {
      expect(findModal().props('title')).toBe(propsDataCE.modalTitle);
      expect(findInitialModalContent().isVisible()).toBe(true);
    });

    it("doesn't show the overage content", () => {
      expect(findOverageModalContent().isVisible()).toBe(false);
    });
  });

  describe('integration', () => {
    it('sets overage and actual feedback message if invalidFeedbackMessage prop is passed', async () => {
      createComponent({
        props: { newUsersToInvite: [123], fullPath: 'project' },
        glFeatures: { overageMembersModal: true },
      });

      // shows initial modal
      expect(findModal().props('title')).toBe(propsDataCE.modalTitle);
      expect(findCEBase().props('invalidFeedbackMessage')).toBe('');

      clickInviteButton();
      await waitForPromises();

      // shows overage modal
      expect(findModal().props('title')).toBe(OVERAGE_MODAL_TITLE);

      wrapper.setProps({ invalidFeedbackMessage: 'invalid message' });
      await nextTick();

      // shows initial modal again
      expect(findModal().props('title')).toBe(propsDataCE.modalTitle);
      expect(findCEBase().props('invalidFeedbackMessage')).toBe('invalid message');
    });
  });
});
