import { GlBadge, GlModal } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { s__ } from '~/locale';
import { state } from 'ee/protected_environments/store/edit/state';
import ProtectedEnvironments from 'ee/protected_environments/protected_environments.vue';
import CreateProtectedEnvironment from 'ee/protected_environments/create_protected_environment.vue';
import Pagination from '~/vue_shared/components/pagination_links.vue';
import { DEVELOPER_ACCESS_LEVEL } from './constants';

const DEFAULT_ENVIRONMENTS = [
  {
    name: 'staging',
    deploy_access_levels: [
      {
        access_level: DEVELOPER_ACCESS_LEVEL,
        access_level_description: 'Deployers + Maintainers',
        group_id: null,
        user_id: null,
      },
      {
        group_id: 1,
        group_inheritance_type: '1',
        access_level_description: 'Some group',
        access_level: null,
        user_id: null,
      },
      { user_id: 1, access_level_description: 'Some user', access_level: null, group_id: null },
    ],
    approval_rules: [
      {
        access_level: 30,
        access_level_description: 'Deployers + Maintainers',
        group_id: null,
        user_id: null,
      },
      {
        group_id: 1,
        group_inheritance_type: '1',
        access_level_description: 'Some group',
        access_level: null,
        user_id: null,
      },
      { user_id: 1, access_level_description: 'Some user', access_level: null, group_id: null },
    ],
  },
];

const DEFAULT_PAGE_INFO = {
  perPage: 20,
  page: 1,
  total: 1,
  totalPages: 1,
  nextPage: null,
  previousPage: null,
};

Vue.use(Vuex);

describe('ee/protected_environments/protected_environments.vue', () => {
  let wrapper;

  const setPageMock = jest.fn(() => Promise.resolve());
  const fetchProtectedEnvironmentsMock = jest.fn(() => Promise.resolve());

  const createStore = ({ pageInfo } = {}) => {
    return new Vuex.Store({
      state: { ...state, pageInfo },
      actions: {
        setPage: setPageMock,
        fetchProtectedEnvironments: fetchProtectedEnvironmentsMock,
      },
    });
  };

  const createComponent = ({
    environments = DEFAULT_ENVIRONMENTS,
    pageInfo = DEFAULT_PAGE_INFO,
  } = {}) => {
    wrapper = mountExtended(ProtectedEnvironments, {
      store: createStore({ pageInfo }),
      propsData: {
        environments,
      },
      scopedSlots: {
        default: '<div :data-testid="props.environment.name">{{props.environment.name}}</div>',
      },
      provide: {
        apiLink: '',
        docsLink: '',
      },
      // Stub access dropdown since it triggers some requests that are out-of-scope here
      stubs: ['AccessDropdown'],
    });
  };

  const findEnvironmentButton = (name) => wrapper.findByRole('button', { name });
  const findPagination = () => wrapper.findComponent(Pagination);
  const findAddButton = () => wrapper.findByTestId('new-environment-button');
  const findAddForm = () => wrapper.findComponent(CreateProtectedEnvironment);
  const findCancelButton = () => wrapper.findByTestId('cancel-button');

  describe('header', () => {
    it('shows a header with the title protected environments', async () => {
      await createComponent();

      expect(
        wrapper
          .findByRole('heading', {
            name: s__('ProtectedEnvironments|Protected environments'),
          })
          .exists(),
      ).toBe(true);
    });

    it('shows a header counting the number of protected environments', async () => {
      await createComponent();

      expect(wrapper.findByTestId('protected-environments-count').text()).toContain('1');
    });
  });

  describe('environment button', () => {
    let button;

    const findBadges = () => wrapper.findAllComponents(GlBadge);
    const findDeploymentBadge = () => findBadges().at(0);
    const findApprovalBadge = () => findBadges().at(1);

    beforeEach(() => {
      createComponent();
      button = findEnvironmentButton('staging');
    });

    it('lists a button with the environment name', () => {
      expect(button.text()).toContain('staging');
    });

    it('shows the number of deployment rules', () => {
      expect(findDeploymentBadge().text()).toBe('3 Deployment Rules');
    });

    it('shows the number of approval rules', () => {
      expect(findApprovalBadge().text()).toBe('3 Approval Rules');
    });

    it('expands the environment section on click', async () => {
      await button.trigger('click');

      expect(wrapper.findByTestId('staging').isVisible()).toBe(true);
    });
  });

  describe('unprotect button', () => {
    let button;
    let modal;
    let environment;

    beforeEach(async () => {
      createComponent();
      [environment] = DEFAULT_ENVIRONMENTS;

      await findEnvironmentButton(environment.name).trigger('click');

      button = wrapper.findByRole('button', { name: s__('ProtectedEnvironments|Unprotect') });
      modal = wrapper.findComponent(GlModal);
    });

    it('shows a button to unprotect environments', () => {
      expect(button.exists()).toBe(true);
    });

    it('triggers a modal to confirm unprotect', async () => {
      await button.trigger('click');

      expect(modal.props('visible')).toBe(true);
    });

    it('emits an unprotect event with environment on modal confirm', async () => {
      await button.trigger('click');

      modal.vm.$emit('primary');

      expect(wrapper.emitted('unprotect')).toEqual([[environment]]);
    });
  });

  describe('pagination', () => {
    it('does not show pagination when there is 1 page', () => {
      createComponent();

      expect(findPagination().exists()).toBe(false);
    });

    it('shows pagination when there are more then 1 page', () => {
      const pageInfo = { ...DEFAULT_PAGE_INFO, totalPages: 2 };
      createComponent({ pageInfo });

      expect(findPagination().props('pageInfo')).toBe(pageInfo);
    });

    it('calls setPage action', () => {
      const pageInfo = { ...DEFAULT_PAGE_INFO, totalPages: 2 };
      createComponent({ pageInfo });

      findPagination().props('change')(2);

      expect(setPageMock).toHaveBeenCalledWith(expect.any(Object), 2);
    });
  });

  describe('add form', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the add button', () => {
      expect(findAddButton().exists()).toBe(true);
    });

    it('does not render the add form', () => {
      expect(findAddForm().exists()).toBe(false);
    });

    describe('when add button is clicked', () => {
      beforeEach(async () => {
        await findAddButton().trigger('click');
      });

      it('shows the add form', () => {
        expect(findAddForm().exists()).toBe(true);
      });

      it('when canceled, hides the add form', async () => {
        await findCancelButton().trigger('click');

        expect(findAddForm().exists()).toBe(false);
      });

      it('when form success, hides the form and refetches', async () => {
        expect(fetchProtectedEnvironmentsMock).not.toHaveBeenCalled();

        await findAddForm().vm.$emit('success');

        expect(findAddForm().exists()).toBe(false);
        expect(fetchProtectedEnvironmentsMock).toHaveBeenCalled();
      });
    });
  });
});
