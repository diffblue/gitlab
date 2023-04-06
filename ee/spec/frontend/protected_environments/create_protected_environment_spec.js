import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { GlAlert, GlCollapsibleListbox, GlFormInput } from '@gitlab/ui';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { TEST_HOST } from 'helpers/test_constants';
import Api from 'ee/api';
import axios from '~/lib/utils/axios_utils';
import AccessDropdown from '~/projects/settings/components/access_dropdown.vue';
import { ACCESS_LEVELS } from 'ee/protected_environments/constants';
import AddApprovers from 'ee/protected_environments/add_approvers.vue';
import CreateProtectedEnvironment from 'ee/protected_environments/create_protected_environment.vue';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { __, s__ } from '~/locale';

const SEARCH_URL = '/search';
const PROJECT_ID = '0';
const API_LINK = `${TEST_HOST}/docs/api.md`;
const DOCS_LINK = `${TEST_HOST}/docs/protected_environments.md`;

describe('ee/protected_environments/create_protected_environment.vue', () => {
  const unmockLocation = useMockLocationHelper();

  let wrapper;
  let mockAxios;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEnvironmentsListbox = () =>
    wrapper.findByTestId('create-environment').findComponent(GlCollapsibleListbox);
  const findAccessDropdown = () =>
    wrapper.findByTestId('create-deployer-dropdown').findComponent(AccessDropdown);
  const findRequiredCountForApprover = (name) =>
    wrapper
      .findAllComponents(GlFormInput)
      .wrappers.find((w) => w.attributes('name') === `approval-count-${name}`);
  const findAddApprovers = () => wrapper.findComponent(AddApprovers);
  const findApproverDropdown = () => findAddApprovers().findComponent(AccessDropdown);
  const findSubmitButton = () =>
    wrapper.findByRole('button', { name: s__('ProtectedEnvironment|Protect') });

  beforeEach(() => {
    window.gon = {
      api_version: 'v4',
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
    searchUnprotectedEnvironmentsUrl = SEARCH_URL,
    projectId = PROJECT_ID,
  } = {}) => {
    wrapper = mountExtended(CreateProtectedEnvironment, {
      propsData: {
        searchUnprotectedEnvironmentsUrl,
        projectId,
      },
      provide: {
        apiLink: API_LINK,
        docsLink: DOCS_LINK,
        accessLevelsData: [
          {
            id: 40,
            text: 'Maintainers',
            before_divider: true,
          },
          {
            id: 30,
            text: 'Developers + Maintainers',
            before_divider: true,
          },
        ],
      },
    });
  };

  const submitForm = async (
    deployAccessLevels = [{ user_id: 1 }],
    name = 'production',
    requiredApprovalCount = '3',
  ) => {
    mockAxios.onGet('/api/v4/users/1').reply(HTTP_STATUS_OK, {
      name: 'root',
      web_url: '/root',
      avatar_url: '/root.png',
      id: 1,
    });
    findAccessDropdown().vm.$emit('hidden', deployAccessLevels);
    findEnvironmentsListbox().vm.$emit('select', name);
    findApproverDropdown().vm.$emit('hidden', deployAccessLevels);
    await waitForPromises();
    findRequiredCountForApprover('root').vm.$emit('input', requiredApprovalCount);
    await nextTick();
    await findSubmitButton().vm.$emit('click');
  };

  describe('alert', () => {
    let alert;

    unmockLocation();

    beforeEach(() => {
      createComponent();

      alert = findAlert();
    });

    it('alerts users to the removal of unified approval rules', () => {
      expect(alert.exists()).toBe(true);
      expect(alert.props('title')).toMatchInterpolatedText(
        s__('ProtectedEnvironments|Unified approval rules have been removed from the settings UI'),
      );
      expect(alert.find('p').text()).toMatchInterpolatedText(
        s__(
          'ProtectedEnvironments|You can still use the %{apiLinkStart}API%{apiLinkEnd} to configure unified approval rules. Consider using %{docsLinkStart}multiple approval rules%{docsLinkEnd} instead, because they provide greater flexibility.',
        ),
      );
    });

    it('links to the API documentation', () => {
      expect(wrapper.findByRole('link', { name: 'API' }).attributes('href')).toBe(API_LINK);
    });

    it('links to the feature documentation', () => {
      expect(
        wrapper.findByRole('link', { name: 'multiple approval rules' }).attributes('href'),
      ).toBe(DOCS_LINK);
    });
  });

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

    mockAxios.onGet(SEARCH_URL, { params: { query } }).reply(HTTP_STATUS_OK, [query]);

    const environmentSearch = findEnvironmentsListbox();
    environmentSearch.vm.$emit('search', query);

    await waitForPromises();
    await nextTick();

    expect(environmentSearch.props('items')).toEqual([{ value: query, text: query }]);
  });

  it('renders a dropdown for selecting approvers', () => {
    createComponent();

    const approvers = findAddApprovers();

    expect(approvers.props()).toMatchObject({
      disabled: false,
    });
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
      approval_rules: [{ user_id: 1, required_approvals: requiredApprovalCount }],
      name,
    });
  });

  describe('on successful protected environment', () => {
    it('should reload the page', async () => {
      createComponent();
      mockAxios.onPost().replyOnce(HTTP_STATUS_OK);
      await submitForm();
      await waitForPromises();

      expect(window.location.reload).toHaveBeenCalled();
    });
  });

  describe('on failed protected environment', () => {
    it('should show an error message', async () => {
      mockAxios.onPost().replyOnce(HTTP_STATUS_BAD_REQUEST, {});
      createComponent();
      await submitForm();
      await waitForPromises();

      expect(findAlert().text()).toBe(__('Failed to protect the environment'));

      expect(window.location.reload).not.toHaveBeenCalled();
    });
  });
});
