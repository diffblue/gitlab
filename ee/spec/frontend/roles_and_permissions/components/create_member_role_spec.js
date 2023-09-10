import { GlFormInput, GlFormSelect, GlFormTextarea, GlFormCheckbox } from '@gitlab/ui';
import { nextTick } from 'vue';
import { createAlert, VARIANT_DANGER } from '~/alert';
import { createMemberRole } from 'ee/api/member_roles_api';
import CreateMemberRole from 'ee/roles_and_permissions/components/create_member_role.vue';
import { I18N_CREATION_ERROR } from 'ee/roles_and_permissions/constants';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('ee/api/member_roles_api');

const mockAlertDismiss = jest.fn();
jest.mock('~/alert', () => ({
  createAlert: jest.fn().mockImplementation(() => ({
    dismiss: mockAlertDismiss,
  })),
}));

describe('CreateMemberRole', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mountExtended(CreateMemberRole, {
      propsData: { groupId: '4' },
      stubs: { GlFormSelect },
    });
  };

  const findButtonSubmit = () => wrapper.findByTestId('submit-button');
  const findButtonCancel = () => wrapper.findByTestId('cancel-button');
  const findNameField = () => wrapper.findComponent(GlFormInput);
  const findCheckboxes = () => wrapper.findAllComponents(GlFormCheckbox);
  const findSelect = () => wrapper.findComponent(GlFormSelect);
  const findOptions = () => findSelect().findAll('option');
  const findTextArea = () => wrapper.findComponent(GlFormTextarea);

  const name = 'My role name';
  const description = 'My description';
  const fillForm = () => {
    findNameField().setValue(name);
    findTextArea().setValue(description);
    findCheckboxes().at(0).find('input').setChecked();
  };

  beforeEach(() => {
    createComponent();
  });

  it('has only one select option', () => {
    const options = findOptions();
    expect(options).toHaveLength(1);
    expect(options.at(0).attributes()).toMatchObject({ value: '10' });
    expect(options.at(0).text()).toBe('Guest');
  });

  it('has multiple checkbox permissions', () => {
    const checkboxes = findCheckboxes();
    const checkboxOneText = checkboxes.at(0).text();
    const checkboxTwoText = checkboxes.at(1).text();
    const checkboxThreeText = checkboxes.at(2).text();

    expect(checkboxOneText).toContain('Read code');
    expect(checkboxOneText).toContain('Allows read-only access to the source code.');

    expect(checkboxTwoText).toContain('Read vulnerability');
    expect(checkboxTwoText).toContain('Allows read-only access to the vulnerability reports.');

    expect(checkboxThreeText).toContain('Admin vulnerability');
    expect(checkboxThreeText).toContain(
      "Allows admin access to the vulnerability reports. 'Read vulnerability' must be selected in order to take effect.",
    );
  });

  it('emits cancel event', () => {
    expect(wrapper.emitted('cancel')).toBeUndefined();

    findButtonCancel().trigger('click');

    expect(wrapper.emitted('cancel')).toHaveLength(1);
  });

  describe('field validation', () => {
    it('shows warnings in the name field', async () => {
      expect(findNameField().classes()).toContain('is-valid');

      findButtonSubmit().trigger('submit');
      await nextTick();

      expect(findNameField().classes()).toContain('is-invalid');
    });

    it('shows warnings if permissions are unchecked', async () => {
      expect(findCheckboxes().at(0).find('input').classes()).not.toContain('is-invalid');

      findButtonSubmit().trigger('submit');
      await nextTick();

      expect(findCheckboxes().at(0).find('input').classes()).toContain('is-invalid');
    });
  });

  describe('when successful submission', () => {
    beforeEach(() => {
      fillForm();
    });

    it('sends the correct data', async () => {
      findButtonSubmit().trigger('submit');
      await waitForPromises();

      expect(createMemberRole).toHaveBeenCalledWith('4', {
        base_access_level: '10',
        name,
        description,
        read_code: 1,
      });
    });

    it('emits success event', async () => {
      expect(wrapper.emitted('success')).toBeUndefined();

      findButtonSubmit().trigger('submit');
      await waitForPromises();

      expect(wrapper.emitted('success')).toHaveLength(1);
    });
  });

  describe('when unsuccessful submission', () => {
    beforeEach(() => {
      fillForm();

      createMemberRole.mockRejectedValue(new Error());
    });

    it('shows alert', async () => {
      findButtonSubmit().trigger('submit');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: I18N_CREATION_ERROR,
        variant: VARIANT_DANGER,
      });
    });

    it('dismisses previous alert', async () => {
      findButtonSubmit().trigger('submit');
      await waitForPromises();

      expect(mockAlertDismiss).toHaveBeenCalledTimes(0);

      findButtonSubmit().trigger('submit');

      expect(mockAlertDismiss).toHaveBeenCalledTimes(1);
    });
  });
});
