import {
  GlDropdown,
  GlDropdownItem,
  GlDatepicker,
  GlFormGroup,
  GlSprintf,
  GlLink,
  GlModal,
} from '@gitlab/ui';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import InviteModalBase from 'ee_else_ce/invite_members/components/invite_modal_base.vue';
import { CANCEL_BUTTON_TEXT, INVITE_BUTTON_TEXT } from '~/invite_members/constants';
import {
  OVERAGE_MODAL_TITLE,
  OVERAGE_MODAL_CONTINUE_BUTTON,
  OVERAGE_MODAL_BACK_BUTTON,
} from 'ee/invite_members/constants';
import { propsData } from 'jest/invite_members/mock_data/modal_base';

describe('InviteModalBase', () => {
  let wrapper;

  const createComponent = (props = {}, glFeatures = {}) => {
    wrapper = shallowMountExtended(InviteModalBase, {
      propsData: {
        ...propsData,
        ...props,
      },
      provide: {
        ...glFeatures,
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          template:
            '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-footer"></slot></div>',
        }),
        GlDropdown: true,
        GlDropdownItem: true,
        GlSprintf,
        GlFormGroup: stubComponent(GlFormGroup, {
          props: ['state', 'invalidFeedback', 'description'],
        }),
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => findDropdown().findAllComponents(GlDropdownItem);
  const findDatepicker = () => wrapper.findComponent(GlDatepicker);
  const findLink = () => wrapper.findComponent(GlLink);
  const findIntroText = () => wrapper.findByTestId('modal-base-intro-text').text();
  const findCancelButton = () => wrapper.findByTestId('cancel-button');
  const findInviteButton = () => wrapper.findByTestId('invite-button');
  const findBackButton = () => wrapper.findByTestId('overage-back-button');
  const findOverageInviteButton = () => wrapper.findByTestId('invite-with-overage-button');
  const findInitialModalContent = () => wrapper.findByTestId('invite-modal-initial-content');
  const findOverageModalContent = () => wrapper.findByTestId('invite-modal-overage-content');
  const findMembersFormGroup = () => wrapper.findByTestId('members-form-group');

  const clickInviteButton = () => findInviteButton().vm.$emit('click');
  const clickBackButton = () => findBackButton().vm.$emit('click');

  describe('rendering the modal', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the modal with the correct title', () => {
      expect(wrapper.findComponent(GlModal).props('title')).toBe(propsData.modalTitle);
    });

    it('displays the introText', () => {
      expect(findIntroText()).toBe(propsData.labelIntroText);
    });

    it('renders the Cancel button text correctly', () => {
      expect(findCancelButton().text()).toBe(CANCEL_BUTTON_TEXT);
    });

    it('renders the Invite button text correctly', () => {
      expect(findInviteButton().text()).toBe(INVITE_BUTTON_TEXT);
    });

    it('renders the Invite button modal without isLoading', () => {
      expect(findInviteButton().props('loading')).toBe(false);
    });

    describe('rendering the access levels dropdown', () => {
      it('sets the default dropdown text to the default access level name', () => {
        expect(findDropdown().attributes('text')).toBe('Guest');
      });

      it('renders dropdown items for each accessLevel', () => {
        expect(findDropdownItems()).toHaveLength(5);
      });
    });

    it('renders the correct link', () => {
      expect(findLink().attributes('href')).toBe(propsData.helpLink);
    });

    it('renders the datepicker', () => {
      expect(findDatepicker().exists()).toBe(true);
    });

    it("doesn't show the overage content", () => {
      expect(findOverageModalContent().isVisible()).toBe(false);
    });

    it('renders the members form group', () => {
      expect(findMembersFormGroup().props()).toEqual({
        description: propsData.formGroupDescription,
        invalidFeedback: '',
        state: null,
      });
    });
  });

  it('with isLoading, shows loading for invite button', () => {
    createComponent({
      isLoading: true,
    });

    expect(findInviteButton().props('loading')).toBe(true);
  });

  it('with invalidFeedbackMessage, set members form group validation state', () => {
    createComponent({
      invalidFeedbackMessage: 'invalid message!',
    });

    expect(findMembersFormGroup().props()).toEqual({
      description: propsData.formGroupDescription,
      invalidFeedback: 'invalid message!',
      state: false,
    });
  });

  describe('displays overage modal', () => {
    beforeEach(() => {
      createComponent({}, { glFeatures: { overageMembersModal: true } });
      clickInviteButton();
    });

    it('renders the modal with the correct title', () => {
      expect(wrapper.findComponent(GlModal).props('title')).toBe(OVERAGE_MODAL_TITLE);
    });

    it('renders the Back button text correctly', () => {
      expect(findBackButton().text()).toBe(OVERAGE_MODAL_BACK_BUTTON);
    });

    it('renders the Continue button text correctly', () => {
      expect(findOverageInviteButton().text()).toBe(OVERAGE_MODAL_CONTINUE_BUTTON);
    });

    it('shows the info text', () => {
      expect(wrapper.findComponent(GlModal).text()).toContain(
        'If you continue, the _name_ group will have 1 seat in use and will be billed for the overage.',
      );
    });

    it('doesn\t show the initial modal content', () => {
      expect(findInitialModalContent().isVisible()).toBe(false);
    });

    describe('when switches back to the initial modal', () => {
      beforeEach(() => clickBackButton());

      it('shows the initial modal', () => {
        expect(wrapper.findComponent(GlModal).props('title')).toBe('_modal_title_');
        expect(findInitialModalContent().isVisible()).toBe(true);
      });

      it("doesn't show the overage content", () => {
        expect(findOverageModalContent().isVisible()).toBe(false);
      });
    });
  });
});
