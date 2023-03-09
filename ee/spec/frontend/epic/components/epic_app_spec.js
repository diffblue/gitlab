import { shallowMount } from '@vue/test-utils';
import EpicApp from 'ee/epic/components/epic_app.vue';
import EpicBody from 'ee/epic/components/epic_body.vue';
import EpicHeader from 'ee/epic/components/epic_header.vue';

describe('EpicAppComponent', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(EpicApp);
  };

  it('renders epic header and epic body', () => {
    createComponent();

    expect(wrapper.findComponent(EpicHeader).exists()).toBe(true);
    expect(wrapper.findComponent(EpicBody).exists()).toBe(true);
  });
});
