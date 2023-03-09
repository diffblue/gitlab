import { shallowMount } from '@vue/test-utils';
import IterationTitle from 'ee/iterations/components/iteration_title.vue';

describe('Iterations title', () => {
  let wrapper;

  const createComponent = (propsData) => {
    wrapper = shallowMount(IterationTitle, {
      propsData,
    });
  };

  it('shows empty state', () => {
    createComponent({ title: 'abc' });

    expect(wrapper.html()).toHaveText('abc');
  });
});
