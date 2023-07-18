import { GlTabs, GlDisclosureDropdown, GlListboxItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

import { MergeRequestGeneratedContent } from '~/merge_requests/generated_content';
import HeaderComponent from '~/vue_shared/components/markdown/header.vue';
import AiActionsDropdown from 'ee/ai/components/ai_actions_dropdown.vue';

jest.mock('~/merge_requests/generated_content');

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

  describe('when AI features are enabled and a generated content class is provided to the component', () => {
    const sha = 'abc123';
    const addendum = `

---

_This description was generated for revision ${sha} using AI_`;
    let gen;

    beforeEach(() => {
      gen = new MergeRequestGeneratedContent({ editor: {} });

      setHTMLFixture(`<div class="md-area">
        <input id="merge_request_diff_head_sha" value="${sha}" />
        <textarea></textarea>
        <div id="root"></div>
      </div>`);

      createWrapper({
        attachTo: '#root',
        provide: {
          editorAiActions: [{ value: 'myAction', title: 'myAction' }],
          mrGeneratedContent: gen,
        },
      });
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    describe('and the AI Actions Dropdown reports a `replace` event', () => {
      it('calls the MergeRequestGeneratedContent instance with the correct value and shows the warning', () => {
        findAiActionsButton().vm.$emit('replace', 'other text');

        expect(gen.setGeneratedContent).toHaveBeenCalledWith(`other text${addendum}`);
        expect(gen.showWarning).toHaveBeenCalled();
      });
    });
  });
});
