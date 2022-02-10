import { shallowMount } from '@vue/test-utils';
import Component from 'ee/subscriptions/new/components/app.vue';
import Modal from 'ee/subscriptions/new/components/modal.vue';
import { stubExperiments } from 'helpers/experimentation_helper';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';

describe('App component', () => {
  let wrapper;

  const createComponent = () => {
    return shallowMount(Component, {
      stubs: { Modal, GitlabExperiment },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('cart_abandonment_modal experiment', () => {
    describe('control', () => {
      beforeEach(() => {
        stubExperiments({ cart_abandonment_modal: 'control' });
        wrapper = createComponent();
      });

      it('matches the snapshot', () => {
        expect(wrapper.element).toMatchSnapshot();
      });

      it('renders the modal', () => {
        expect(wrapper.findComponent(Modal).exists()).toBe(false);
      });
    });

    describe('candidate', () => {
      beforeEach(() => {
        stubExperiments({ cart_abandonment_modal: 'candidate' });
        wrapper = createComponent();
      });

      it('matches the snapshot', () => {
        expect(wrapper.element).toMatchSnapshot();
      });

      it('renders the modal', () => {
        expect(wrapper.findComponent(Modal).exists()).toBe(true);
      });
    });
  });
});
