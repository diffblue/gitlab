import { shallowMount } from '@vue/test-utils';
import EpicApp from 'ee/epic/components/epic_app.vue';
import EpicBody from 'ee/epic/components/epic_body.vue';

describe('EpicAppComponent', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(EpicApp);
  };

  it('renders epic body', () => {
    createComponent();

    expect(wrapper.findComponent(EpicBody).exists()).toBe(true);
  });
});
