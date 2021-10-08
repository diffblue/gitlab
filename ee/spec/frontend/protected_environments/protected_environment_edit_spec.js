import MockAdapter from 'axios-mock-adapter';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import AccessDropdown from '~/projects/settings/components/access_dropdown.vue';
import ProtectedEnvironmentEdit, {
  i18n,
} from 'ee/protected_environments/protected_environment_edit.vue';
import { ACCESS_LEVELS, LEVEL_TYPES } from 'ee/protected_environments/constants';
import createFlash from '~/flash';
import httpStatusCodes from '~/lib/utils/http_status';

jest.mock('~/flash');
const $toast = {
  show: jest.fn(),
};

describe('Protected Environment Edit', () => {
  let wrapper;
  let originalGon;
  let mockAxios;

  const url = 'http://some.url';
  const parentContainer = document.createElement('div');

  beforeEach(() => {
    originalGon = window.gon;

    window.gon = {
      ...window.gon,
      deploy_access_levels: {
        roles: [],
      },
    };
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    window.gon = originalGon;
    mockAxios.restore();
    wrapper.destroy();
  });

  const createComponent = ({ preselectedItems = [], disabled = false, label = '' } = {}) => {
    wrapper = shallowMount(ProtectedEnvironmentEdit, {
      propsData: {
        parentContainer,
        url,
        disabled,
        label,
        preselectedItems,
      },
      mocks: {
        $toast,
      },
    });
  };

  const findAccessDropdown = () => wrapper.findComponent(AccessDropdown);

  it('renders AccessDropdown and passes down the props', () => {
    const label = 'Update permissions';
    const disabled = true;
    const preselectedItems = [1, 2, 3];

    createComponent({
      label,
      disabled,
      preselectedItems,
    });
    const dropdown = findAccessDropdown();

    expect(dropdown.props()).toMatchObject({
      accessLevel: ACCESS_LEVELS.DEPLOY,
      disabled,
      label,
      preselectedItems,
    });
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
      mockAxios
        .onPatch()
        .replyOnce(httpStatusCodes.OK, { [ACCESS_LEVELS.DEPLOY]: updatedPermissions });
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
      mockAxios.onPatch().replyOnce(httpStatusCodes.BAD_REQUEST, {});
      createComponent();
    });

    it('should show error message', async () => {
      findAccessDropdown().vm.$emit('hidden', [{ user_id: 1 }]);
      await waitForPromises();
      expect(createFlash).toHaveBeenCalledWith({
        message: i18n.failureMessage,
        parent: parentContainer,
      });
    });
  });
});
