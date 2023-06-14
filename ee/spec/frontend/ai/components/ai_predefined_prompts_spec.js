import { GlButton } from '@gitlab/ui';
import AiPredefinedPrompts from 'ee/ai/components/ai_predefined_prompts.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('AiPredefinedPrompts', () => {
  let wrapper;
  const predefinedPrompt1 = 'foo';
  const predefinedPrompt2 = 'bar';

  const createComponent = () => {
    wrapper = shallowMountExtended(AiPredefinedPrompts, {
      propsData: {
        prompts: [predefinedPrompt1, predefinedPrompt2],
      },
    });
  };

  const findButtons = () => wrapper.findAllComponents(GlButton);

  it('renders a button for each predefined prompt', () => {
    createComponent();

    expect(findButtons()).toHaveLength(2);
  });

  it('emits the click event when a button is clicked', () => {
    createComponent();

    findButtons().at(0).vm.$emit('click');
    expect(wrapper.emitted('click')).toEqual([[predefinedPrompt1]]);

    findButtons().at(1).vm.$emit('click');
    expect(wrapper.emitted('click')).toEqual([[predefinedPrompt1], [predefinedPrompt2]]);
  });
});
