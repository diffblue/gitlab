import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubExperiments } from 'helpers/experimentation_helper';

import { getExperimentData } from '~/experimentation/utils';
import CardSecurityDiscoverApp from 'ee/vue_shared/discover/card_security_discover_app.vue';
import HandRaiseLeadButton from 'ee/hand_raise_leads/hand_raise_lead/components/hand_raise_lead_button.vue';
import MovePersonalProjectToGroupModal from 'ee/projects/components/move_personal_project_to_group_modal.vue';
import { mockTracking } from 'helpers/tracking_helper';
import createMockApollo from 'helpers/mock_apollo_helper';

Vue.use(VueApollo);

describe('Card security discover app', () => {
  let wrapper;
  const project = {
    id: 1,
    name: 'Awesome Project',
  };

  const createComponent = ({ extraPropsData = {}, mountFn = shallowMountExtended } = {}) => {
    const propsData = {
      project,
      linkMain: '/link/main',
      linkSecondary: '/link/secondary',
      ...extraPropsData,
    };
    wrapper = mountFn(CardSecurityDiscoverApp, {
      propsData,
      apolloProvider: createMockApollo([], {}),
      provide: {
        small: false,
        user: {
          namespaceId: '1',
          userName: 'joe',
          firstName: 'Joe',
          lastName: 'Doe',
          companyName: 'ACME',
        },
      },
    });
  };

  describe('Project discover carousel', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders component properly', () => {
      expect(wrapper.findComponent(CardSecurityDiscoverApp).exists()).toBe(true);
    });

    it('does not render the MovePersonalProjectToGroupModal', () => {
      expect(wrapper.findComponent(MovePersonalProjectToGroupModal).exists()).toBe(false);
    });

    it('renders discover title properly', () => {
      expect(wrapper.find('.discover-title').html()).toContain(
        'Security capabilities, integrated into your development lifecycle',
      );
    });

    it('renders discover upgrade links properly', () => {
      expect(wrapper.findByTestId('discover-button-upgrade').html()).toContain('Upgrade now');
      expect(wrapper.findByTestId('discover-button-upgrade').attributes('href')).toBe(
        wrapper.props().linkSecondary,
      );
    });

    it('renders discover trial links properly', () => {
      expect(wrapper.findByTestId('discover-button-trial').html()).toContain('Start a free trial');
      expect(wrapper.findByTestId('discover-button-trial').attributes('href')).toBe(
        wrapper.props().linkMain,
      );
    });

    describe('Tracking', () => {
      let spy;

      beforeEach(() => {
        stubExperiments({ pql_three_cta_test: 'candidate' });
        spy = mockTracking('_category_', wrapper.element, jest.spyOn);
      });

      it('tracks an event when clicked on upgrade', () => {
        wrapper.findByTestId('discover-button-upgrade').trigger('click');

        expect(spy).toHaveBeenCalledWith('_category_', 'click_button', {
          label: 'security-discover-upgrade-cta',
          property: '0',
          context: {
            data: {
              experiment: 'pql_three_cta_test',
              variant: 'candidate',
            },
            schema: 'iglu:com.gitlab/gitlab_experiment/jsonschema/1-0-0',
          },
        });
      });

      it('tracks an event when clicked on trial', () => {
        wrapper.findByTestId('discover-button-trial').trigger('click');

        expect(spy).toHaveBeenCalledWith('_category_', 'click_button', {
          label: 'security-discover-trial-cta',
          property: '0',
          context: {
            data: {
              experiment: 'pql_three_cta_test',
              variant: 'candidate',
            },
            schema: 'iglu:com.gitlab/gitlab_experiment/jsonschema/1-0-0',
          },
        });
      });

      it('tracks an event when clicked on a slider', () => {
        const expectedCategory = undefined;

        document.body.dataset.page = '_category_';
        wrapper.vm.onSlideStart(1);

        expect(spy).toHaveBeenCalledWith(expectedCategory, 'click_button', {
          label: 'security-discover-carousel',
          property: 'sliding0-1',
        });
      });
    });
  });

  describe('Personal Project', () => {
    beforeEach(() => {
      createComponent({ extraPropsData: { project: { ...project, isPersonal: true } } });
    });

    it('renders the MovePersonalProjectToGroupModal properly', () => {
      expect(wrapper.findComponent(MovePersonalProjectToGroupModal).exists()).toBe(true);
    });

    it('renders discover upgrade links properly', () => {
      expect(wrapper.findByTestId('discover-button-upgrade').html()).toContain('Upgrade now');
    });

    it('renders discover trial links properly', () => {
      expect(wrapper.findByTestId('discover-button-trial').html()).toContain('Start a free trial');
    });
  });

  describe('Experiment pql_three_cta_test', () => {
    let originalGl;

    beforeEach(() => {
      originalGl = window.gl;
    });

    afterEach(() => {
      window.gl = originalGl;
    });

    it('for control sets control and not show hand raise lead', () => {
      stubExperiments({ pql_three_cta_test: 'control' });
      createComponent({ mountFn: mount });
      expect(getExperimentData('pql_three_cta_test')).toEqual({
        experiment: 'pql_three_cta_test',
        variant: 'control',
      });
      expect(wrapper.findComponent(HandRaiseLeadButton).exists()).toBe(false);
    });

    it('for candidate shows hand raise leads', () => {
      stubExperiments({ pql_three_cta_test: 'candidate' });
      createComponent({ mountFn: mount });
      expect(getExperimentData('pql_three_cta_test')).toEqual({
        experiment: 'pql_three_cta_test',
        variant: 'candidate',
      });
      expect(wrapper.findComponent(HandRaiseLeadButton).exists()).toBe(true);
    });
  });
});
