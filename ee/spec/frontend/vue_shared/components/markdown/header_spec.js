import { GlTabs, GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import HeaderComponent from '~/vue_shared/components/markdown/header.vue';
import AiActionsDropdown from 'ee_component/vue_shared/components/markdown/ai_actions_dropdown.vue';

describe('Markdown field header component', () => {
  let wrapper;

  const createWrapper = (props, provide = {}) => {
    wrapper = shallowMountExtended(HeaderComponent, {
      propsData: {
        previewMarkdown: false,
        ...props,
      },
      stubs: { GlTabs, AiActionsDropdown, GlCollapsibleListbox, GlListboxItem },
      provide,
    });
  };

  const findAiActionsButton = () => wrapper.findComponent(AiActionsDropdown);

  it.each([true, false])(
    'renders/does not render "AI actions" when feature flags are "%s"',
    (enabled) => {
      createWrapper(
        {},
        {
          issuableId: 1,
          glFeatures: {
            openaiExperimentation: enabled,
            summarizeComments: enabled,
            summarizeNotes: enabled,
          },
        },
      );

      expect(findAiActionsButton().exists()).toBe(enabled);
    },
  );
});
