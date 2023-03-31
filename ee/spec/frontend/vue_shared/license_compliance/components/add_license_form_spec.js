import { GlFormRadio, GlFormRadioGroup } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import LicenseIssueBody from 'ee/vue_shared/license_compliance/components/add_license_form.vue';
import AddLicenseFormDropdown from 'ee/vue_shared/license_compliance/components/add_license_form_dropdown.vue';
import { LICENSE_APPROVAL_STATUS } from 'ee/vue_shared/license_compliance/constants';

const KNOWN_LICENSES = [{ name: 'BSD' }, { name: 'Apache' }];

let wrapper;

const createComponent = (props = {}, mountFn = shallowMount) => {
  wrapper = mountFn(LicenseIssueBody, { propsData: { knownLicenses: KNOWN_LICENSES, ...props } });
};

describe('AddLicenseForm', () => {
  const findSubmitButton = () => wrapper.find('.js-submit');
  const findCancelButton = () => wrapper.find('.js-cancel');
  const findRadioInputs = () =>
    wrapper.findComponent(GlFormRadioGroup).findAllComponents(GlFormRadio);
  const findRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findAddLicenseFormDropdown = () => wrapper.findComponent(AddLicenseFormDropdown);
  const findFeedbackElement = () => wrapper.find('.invalid-feedback');

  beforeEach(() => {
    createComponent();
  });

  describe('interaction', () => {
    it('clicking the Submit button submits the data and closes the form', async () => {
      const name = 'LICENSE_TEST';

      createComponent({}, mount);
      findAddLicenseFormDropdown().vm.$emit('update-selected-license', name);
      findRadioGroup().vm.$emit('input', LICENSE_APPROVAL_STATUS.ALLOWED);
      await nextTick();

      findSubmitButton().trigger('click');

      expect(wrapper.emitted('addLicense')[0][0]).toEqual({
        newStatus: LICENSE_APPROVAL_STATUS.ALLOWED,
        license: { name },
      });
    });

    it('clicking the Cancel button closes the form', () => {
      createComponent({}, mount);
      expect(wrapper.emitted('closeForm')).toBeUndefined();

      findCancelButton().trigger('click');

      expect(wrapper.emitted('closeForm')).toHaveLength(1);
    });
  });

  describe('computed', () => {
    describe('submitDisabled', () => {
      it('is true if the approvalStatus is empty', async () => {
        findAddLicenseFormDropdown().vm.$emit('update-selected-license', 'FOO');
        findRadioGroup().vm.$emit('input', '');
        await nextTick();

        expect(findSubmitButton().props('disabled')).toBe(true);
      });

      it('is true if the licenseName is empty', async () => {
        findAddLicenseFormDropdown().vm.$emit('update-selected-license', '');
        findRadioGroup().vm.$emit('input', LICENSE_APPROVAL_STATUS.ALLOWED);
        await nextTick();

        expect(findSubmitButton().props('disabled')).toBe(true);
      });

      it('is true if the entered license is duplicated', async () => {
        createComponent({ managedLicenses: [{ name: 'FOO' }] });
        findAddLicenseFormDropdown().vm.$emit('update-selected-license', 'FOO');
        findRadioGroup().vm.$emit('input', LICENSE_APPROVAL_STATUS.ALLOWED);
        await nextTick();

        expect(findSubmitButton().props('disabled')).toBe(true);
      });
    });

    describe('isInvalidLicense', () => {
      it('is true if the entered license is duplicated', async () => {
        createComponent({ managedLicenses: [{ name: 'FOO' }] });
        findAddLicenseFormDropdown().vm.$emit('update-selected-license', 'FOO');
        await nextTick();

        expect(findFeedbackElement().classes()).toContain('d-block');
      });

      it('is false if the entered license is unique', async () => {
        createComponent({ managedLicenses: [{ name: 'FOO' }] });
        findAddLicenseFormDropdown().vm.$emit('update-selected-license', 'FOO2');
        await nextTick();

        expect(findFeedbackElement().classes()).not.toContain('d-block');
      });
    });
  });

  describe('template', () => {
    it('renders the license select dropdown', () => {
      expect(findAddLicenseFormDropdown().exists()).toBe(true);
    });

    describe('license approval radio list', () => {
      it('renders the correct approval options', () => {
        const approvalOptions = findRadioInputs();

        expect(approvalOptions).toHaveLength(2);
        expect(approvalOptions.at(0).text()).toContain('Allow');
        expect(approvalOptions.at(1).text()).toContain('Deny');
      });

      it('renders the approval option descriptions', () => {
        const approvalOptions = findRadioInputs();

        expect(approvalOptions.at(0).text()).toContain(
          'Acceptable license to be used in the project',
        );
        expect(approvalOptions.at(1).text()).toContain(
          'Disallow merge request if detected and will instruct developer to remove',
        );
      });
    });

    it('renders error text, if there is a duplicate license', async () => {
      createComponent({ managedLicenses: [{ name: 'FOO' }] });
      findAddLicenseFormDropdown().vm.$emit('update-selected-license', 'FOO');
      await nextTick();

      const feedbackElement = findFeedbackElement();

      expect(feedbackElement.exists()).toBe(true);
      expect(feedbackElement.classes()).toContain('d-block');
      expect(feedbackElement.text()).toBe('This license already exists in this project.');
    });

    it('shows radio button descriptions', async () => {
      wrapper = shallowMount(LicenseIssueBody, {
        propsData: {
          managedLicenses: [{ name: 'FOO' }],
          knownLicenses: KNOWN_LICENSES,
        },
      });

      await nextTick();

      const descriptionElement = wrapper.findAll('.text-secondary');

      expect(descriptionElement.at(0).text()).toBe('Acceptable license to be used in the project');

      expect(descriptionElement.at(1).text()).toBe(
        'Disallow merge request if detected and will instruct developer to remove',
      );
    });

    it('disables submit, if the form is invalid', async () => {
      findAddLicenseFormDropdown().vm.$emit('update-selected-license', '');
      await nextTick();

      expect(findSubmitButton().props().disabled).toBe(true);

      const submitButton = findSubmitButton();

      expect(submitButton.exists()).toBe(true);
      expect(submitButton.props().disabled).toBe(true);
    });

    it('disables submit and cancel while a new license is being added', async () => {
      wrapper.setProps({ loading: true });
      await nextTick();

      const submitButton = findSubmitButton();
      const cancelButton = findCancelButton();

      expect(submitButton.exists()).toBe(true);
      expect(submitButton.props().disabled).toBe(true);
      expect(cancelButton.exists()).toBe(true);
      expect(cancelButton.props().disabled).toBe(true);
    });
  });
});
