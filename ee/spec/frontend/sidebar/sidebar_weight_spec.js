import { shallowMount } from '@vue/test-utils';
import SidebarWeight from 'ee/sidebar/components/weight/sidebar_weight.vue';
import SidebarMediator from 'ee/sidebar/sidebar_mediator';
import SidebarStore from 'ee/sidebar/stores/sidebar_store';
import eventHub from '~/sidebar/event_hub';
import SidebarService from '~/sidebar/services/sidebar_service';
import Mock from './ee_mock_data';

describe('Sidebar Weight', () => {
  let sidebarMediator;
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(SidebarWeight);
  };

  beforeEach(() => {
    // Set up the stores, services, etc
    sidebarMediator = new SidebarMediator(Mock.mediator);
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
    SidebarService.singleton = null;
    SidebarStore.singleton = null;
    SidebarMediator.singleton = null;
  });

  it('calls the mediator updateWeight on event', () => {
    jest.spyOn(SidebarMediator.prototype, 'updateWeight').mockReturnValue(Promise.resolve());

    createComponent({
      mediator: sidebarMediator,
    });

    eventHub.$emit('updateWeight', { value: '' });

    expect(SidebarMediator.prototype.updateWeight).toHaveBeenCalled();
  });
});
