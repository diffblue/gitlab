import { GlBadge, GlModal } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { s__ } from '~/locale';
import ProtectedEnvironments from 'ee/protected_environments/protected_environments.vue';
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

describe('ee/protected_environments/protected_environments.vue', () => {
  let wrapper;

  const createComponent = ({ environments = DEFAULT_ENVIRONMENTS } = {}) => {
    wrapper = mountExtended(ProtectedEnvironments, {
      propsData: {
        environments,
      },
      scopedSlots: {
        default: '<div :data-testid="props.environment.name">{{props.environment.name}}</div>',
      },
    });
  };

  const findEnvironmentButton = (name) => wrapper.findByRole('button', { name });

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
});
