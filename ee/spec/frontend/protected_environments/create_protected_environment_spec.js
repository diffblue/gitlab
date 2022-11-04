import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { GlAlert, GlListbox } from '@gitlab/ui';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Api from 'ee/api';
import axios from '~/lib/utils/axios_utils';
import AccessDropdown from '~/projects/settings/components/access_dropdown.vue';
import { ACCESS_LEVELS } from 'ee/protected_environments/constants';
import CreateProtectedEnvironment from 'ee/protected_environments/create_protected_environment.vue';
import httpStatusCodes from '~/lib/utils/http_status';
import { __, s__ } from '~/locale';

const SEARCH_URL = '/search';
const PROJECT_ID = '0';

describe('ee/protected_environments/create_protected_environment.vue', () => {
  useMockLocationHelper();

  let wrapper;
  let originalGon;
  let mockAxios;

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
  });

  const createComponent = ({
    searchUnprotectedEnvironmentsUrl = SEARCH_URL,
    projectId = PROJECT_ID,
  } = {}) => {
    wrapper = mountExtended(CreateProtectedEnvironment, {
      propsData: {
        searchUnprotectedEnvironmentsUrl,
        projectId,
      },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEnvironmentsListbox = () => wrapper.findAllComponents(GlListbox).at(0);
  const findAccessDropdown = () => wrapper.findComponent(AccessDropdown);
  const findRequiredCountSelect = () => wrapper.findAllComponents(GlListbox).at(1);
  const findSubmitButton = () =>
    wrapper.findByRole('button', { name: s__('ProtectedEnvironment|Protect') });

  const submitForm = async (
    deployAccessLevels = [{ user_id: 1 }],
    name = 'production',
    requiredApprovalCount = '3',
  ) => {
    findAccessDropdown().vm.$emit('hidden', deployAccessLevels);
    findEnvironmentsListbox().vm.$emit('select', name);
    findRequiredCountSelect().vm.$emit('select', requiredApprovalCount);
    await findSubmitButton().vm.$emit('click');
  };

  it('renders AccessDropdown and passes down the props', () => {
    createComponent();
    const dropdown = findAccessDropdown();

    expect(dropdown.props()).toMatchObject({
      accessLevel: ACCESS_LEVELS.DEPLOY,
      label: __('Select users'),
    });
  });

  it('searchs the environment name', async () => {
    const query = 'staging';
    createComponent();

    mockAxios.onGet(SEARCH_URL, { params: { query } }).reply(httpStatusCodes.OK, [query]);

    const environmentSearch = findEnvironmentsListbox();
    environmentSearch.vm.$emit('search', query);

    await waitForPromises();
    await nextTick();

    expect(environmentSearch.props('items')).toEqual([{ value: query, text: query }]);
  });

  it('renders a select for the required approval count', () => {
    createComponent();

    const count = findRequiredCountSelect();

    expect(count.props('toggleText')).toBe('0');
  });

  it('should make a request when submit is clicked', async () => {
    createComponent();

    jest.spyOn(Api, 'createProtectedEnvironment');
    const deployAccessLevels = [{ user_id: 1 }];
    const name = 'production';
    const requiredApprovalCount = '3';

    await submitForm(deployAccessLevels, name, requiredApprovalCount);

    expect(Api.createProtectedEnvironment).toHaveBeenCalledWith(PROJECT_ID, {
      deploy_access_levels: deployAccessLevels,
      required_approval_count: requiredApprovalCount,
      name,
    });
  });

  describe('on successful protected environment', () => {
    it('should reload the page', async () => {
      createComponent();
      mockAxios.onPost().replyOnce(httpStatusCodes.OK);
      await submitForm();
      await waitForPromises();

      expect(window.location.reload).toHaveBeenCalled();
    });
  });

  describe('on failed protected environment', () => {
    it('should show an error message', async () => {
      mockAxios.onPost().replyOnce(httpStatusCodes.BAD_REQUEST, {});
      createComponent();
      await submitForm();
      await waitForPromises();

      expect(findAlert().text()).toBe(__('Failed to protect the environment'));

      expect(window.location.reload).not.toHaveBeenCalled();
    });
  });
});
