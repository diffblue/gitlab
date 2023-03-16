import MockAdapter from 'axios-mock-adapter';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import AccessDropdown from '~/projects/settings/components/access_dropdown.vue';
import ProtectedEnvironmentEdit, {
  i18n,
} from 'ee/protected_environments/protected_environment_edit.vue';
import { ACCESS_LEVELS, LEVEL_TYPES } from 'ee/protected_environments/constants';
import { createAlert } from '~/alert';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';

jest.mock('~/alert');
const $toast = {
  show: jest.fn(),
};

describe('Protected Environment Edit', () => {
  let wrapper;
  let mockAxios;

  const url = 'http://some.url';
  const parentContainer = document.createElement('div');

  beforeEach(() => {
    window.gon = {
      deploy_access_levels: {
        roles: [],
      },
    };
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    mockAxios.restore();
  });

  const createComponent = ({
    preselectedItems = [],
    disabled = false,
    environmentName = '',
    environmentLink = '',
    deleteProtectedEnvironmentLink = '',
    requiredApprovalCount = 0,
  } = {}) => {
    wrapper = mountExtended(ProtectedEnvironmentEdit, {
      propsData: {
        parentContainer,
        url,
        disabled,
        preselectedItems,
        environmentName,
        environmentLink,
        deleteProtectedEnvironmentLink,
        requiredApprovalCount,
      },
      mocks: {
        $toast,
      },
    });
  };

  const findAccessDropdown = () => wrapper.findComponent(AccessDropdown);

  const findRequiredCountSelect = () => wrapper.findByRole('combobox');

  it('renders AccessDropdown and passes down the props', () => {
    const disabled = true;
    const preselectedItems = [1, 2, 3];

    createComponent({
      disabled,
      preselectedItems,
    });
    const dropdown = findAccessDropdown();

    expect(dropdown.props()).toMatchObject({
      accessLevel: ACCESS_LEVELS.DEPLOY,
      disabled,
      preselectedItems,
      label: i18n.label,
    });
  });

  it('renders the environment name', () => {
    const environmentName = 'staging';
    createComponent({
      environmentName,
    });

    const name = wrapper.findByText(environmentName);

    expect(name.exists()).toBe(true);
  });

  it('renders a link to the environment if it exists', () => {
    const environmentName = 'staging';
    const environmentLink = '/staging';
    createComponent({
      environmentName,
      environmentLink,
    });

    const name = wrapper.findByRole('link', { name: environmentName });

    expect(name.attributes('href')).toBe(environmentLink);
  });

  it('renders a select for the required approval count', () => {
    const requiredApprovalCount = 0;

    createComponent({
      requiredApprovalCount,
    });

    const count = findRequiredCountSelect();

    expect(count.element.value).toBe(requiredApprovalCount.toString());
  });

  it('should NOT make a request if updated permissions are the same as preselected', () => {
    createComponent();

    jest.spyOn(axios, 'patch');
    findAccessDropdown().vm.$emit('hidden', []);
    expect(axios.patch).not.toHaveBeenCalled();
  });

  it('should make a request if updated permissions are different than preselected', () => {
    createComponent();

    jest.spyOn(axios, 'patch');
    const newPermissions = [{ user_id: 1 }];
    findAccessDropdown().vm.$emit('hidden', newPermissions);
    expect(axios.patch).toHaveBeenCalledWith(url, {
      protected_environment: { deploy_access_levels_attributes: newPermissions },
    });
  });

  describe('on successful permissions update', () => {
    beforeEach(async () => {
      createComponent();
      const updatedPermissions = [
        { user_id: 1, id: 1 },
        { group_id: 1, id: 2 },
        { access_level: 3, id: 3 },
      ];
      mockAxios.onPatch().replyOnce(HTTP_STATUS_OK, { [ACCESS_LEVELS.DEPLOY]: updatedPermissions });
      findAccessDropdown().vm.$emit('hidden', [{ user_id: 1 }]);
      await waitForPromises();
    });

    it('should show a toast with success message', () => {
      expect($toast.show).toHaveBeenCalledWith(i18n.successMessage);
    });

    it('should update preselected', () => {
      const newPreselected = [
        { user_id: 1, id: 1, type: LEVEL_TYPES.USER },
        { group_id: 1, id: 2, type: LEVEL_TYPES.GROUP },
        { access_level: 3, id: 3, type: LEVEL_TYPES.ROLE },
      ];
      expect(findAccessDropdown().props('preselectedItems')).toEqual(newPreselected);
    });
  });

  describe('on permissions update failure', () => {
    beforeEach(() => {
      mockAxios.onPatch().replyOnce(HTTP_STATUS_BAD_REQUEST, {});
      createComponent();
    });

    it('should show error message', async () => {
      findAccessDropdown().vm.$emit('hidden', [{ user_id: 1 }]);
      await waitForPromises();
      expect(createAlert).toHaveBeenCalledWith({
        message: i18n.failureMessage,
        parent: parentContainer,
      });
    });
  });

  describe('on count update success', () => {
    let updatedCount = 5;

    beforeEach(async () => {
      createComponent();
      updatedCount = 5;
      mockAxios.onPatch().replyOnce(HTTP_STATUS_OK, { required_approval_count: updatedCount });
      findRequiredCountSelect().setValue(updatedCount);
      await waitForPromises();
    });

    it('should show a toast with success message', () => {
      expect($toast.show).toHaveBeenCalledWith(i18n.successMessage);
    });

    it('should update count', () => {
      expect(findRequiredCountSelect().element.value).toBe(updatedCount.toString());
    });
  });

  describe('on count update failure', () => {
    beforeEach(() => {
      mockAxios.onPatch().replyOnce(HTTP_STATUS_BAD_REQUEST, {});
      createComponent();
    });

    it('should show error message', async () => {
      findRequiredCountSelect().setValue(5);
      await waitForPromises();
      expect(createAlert).toHaveBeenCalledWith({
        message: i18n.failureMessage,
        parent: parentContainer,
      });
    });
  });
});
