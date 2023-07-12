import { GlTabs, GlDisclosureDropdown, GlListboxItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import HeaderComponent from '~/vue_shared/components/markdown/header.vue';
import AiActionsDropdown from 'ee/ai/components/ai_actions_dropdown.vue';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

describe('Markdown field header component', () => {
  document.execCommand = jest.fn();

  let wrapper;

  const createWrapper = ({ props, provide = {}, attachTo = document.body } = {}) => {
    wrapper = shallowMountExtended(HeaderComponent, {
      attachTo,
      propsData: {
        previewMarkdown: false,
        ...props,
      },
      stubs: { GlTabs, AiActionsDropdown, GlDisclosureDropdown, GlListboxItem },
      provide,
    });
  };

  const findAiActionsButton = () => wrapper.findComponent(AiActionsDropdown);

  it.each([true, false])(
    'renders/does not render "AI actions" when actions are "%s"',
    (enabled) => {
      createWrapper({
        provide: {
          editorAiActions: enabled ? [{ value: 'myAction', title: 'myAction' }] : [],
        },
      });

      expect(findAiActionsButton().exists()).toBe(enabled);
    },
  );

  describe('generated text responses', () => {
    const sha = 'abc123';
    const addendum = `

---

_This description was generated for revision ${sha} using AI_`;

    beforeEach(() => {
      setHTMLFixture(`<div class="md-area">
        <input id="merge_request_diff_head_sha" value="${sha}" />
        <textarea></textarea>
        <div id="root"></div>
      </div>`);
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('replaces the text content when the AI actions dropdown reports a `replace` event', () => {
      const text = document.querySelector('textarea');

      text.value = 'test';

      createWrapper({
        attachTo: '#root',
        provide: {
          editorAiActions: [{ value: 'myAction', title: 'myAction' }],
        },
      });

      expect(text.value).toBe('test');

      findAiActionsButton().vm.$emit('replace', 'other text');

      expect(text.value).toBe(`other text${addendum}`);
    });
  });
});
