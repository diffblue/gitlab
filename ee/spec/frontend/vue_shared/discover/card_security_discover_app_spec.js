import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import CardSecurityDiscoverApp from 'ee/vue_shared/discover/card_security_discover_app.vue';
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

  const createComponent = (extraPropsData = {}) => {
    const propsData = {
      project,
      linkMain: '/link/main',
      linkSecondary: '/link/secondary',
      ...extraPropsData,
    };
    wrapper = shallowMountExtended(CardSecurityDiscoverApp, {
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
        spy = mockTracking('_category_', wrapper.element, jest.spyOn);
      });

      it('tracks an event when clicked on upgrade', () => {
        wrapper.findByTestId('discover-button-upgrade').trigger('click');

        expect(spy).toHaveBeenCalledWith('_category_', 'click_button', {
          label: 'security-discover-upgrade-cta',
          property: '0',
        });
      });

      it('tracks an event when clicked on trial', () => {
        wrapper.findByTestId('discover-button-trial').trigger('click');

        expect(spy).toHaveBeenCalledWith('_category_', 'click_button', {
          label: 'security-discover-trial-cta',
          property: '0',
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
      createComponent({ project: { ...project, isPersonal: true } });
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
});
