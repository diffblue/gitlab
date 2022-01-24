import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import BlockingMrInputRoot from 'ee/projects/merge_requests/blocking_mr_input_root.vue';
import RelatedIssuableInput from '~/related_issues/components/related_issuable_input.vue';

describe('blocking mr input root', () => {
  let wrapper;

  const getInput = () => wrapper.findComponent(RelatedIssuableInput);
  const addTokenizedInput = (input) => {
    getInput().vm.$emit('addIssuableFormInput', {
      untouchedRawReferences: [input],
      touchedReference: '',
    });
  };
  const addInput = (input) => {
    getInput().vm.$emit('addIssuableFormInput', {
      untouchedRawReferences: [],
      touchedReference: input,
    });
  };
  const removeRef = (index) => {
    getInput().vm.$emit('pendingIssuableRemoveRequest', index);
  };
  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(BlockingMrInputRoot, { propsData });
  };

  it('does not keep duplicate references', () => {
    createComponent();
    const input = '!1';

    addTokenizedInput(input);
    addTokenizedInput(input);

    expect(wrapper.vm.references).toEqual(['!1']);
  });

  it('updates input value to empty string when adding a tokenized input', () => {
    createComponent();

    addTokenizedInput('foo');

    expect(wrapper.vm.inputValue).toBe('');
  });

  it('updates input value to ref when typing into input (before adding whitespace)', () => {
    createComponent();

    addInput('foo');

    expect(wrapper.vm.inputValue).toBe('foo');
  });

  it('does not reorder when adding a ref that already exists', () => {
    const input = '!1';
    createComponent({
      existingRefs: [input, '!2'],
    });

    addTokenizedInput(input, wrapper);

    expect(wrapper.vm.references).toEqual(['!1', '!2']);
  });

  it('does not add empty reference on blur', () => {
    createComponent();

    getInput().vm.$emit('addIssuableFormBlur', '');

    expect(wrapper.vm.references).toHaveLength(0);
  });

  describe('hidden inputs', () => {
    const createHiddenInputExpectation = (selector) => (bool) => {
      expect(wrapper.find(selector).element.value).toBe(`${bool}`);
    };

    describe('update_blocking_merge_request_refs', () => {
      const expectShouldUpdateRefsToBe = createHiddenInputExpectation(
        'input[name="merge_request[update_blocking_merge_request_refs]"]',
      );

      it('is false when nothing happens', () => {
        createComponent();

        expectShouldUpdateRefsToBe(false);
      });

      it('is true after a ref is removed', async () => {
        createComponent({ existingRefs: ['!1'] });
        removeRef(0);

        await nextTick();
        expectShouldUpdateRefsToBe(true);
      });

      it('is true after a ref is added', async () => {
        createComponent();
        addTokenizedInput('foo');

        await nextTick();
        expectShouldUpdateRefsToBe(true);
      });
    });

    describe('remove_hidden_blocking_merge_requests', () => {
      const expectRemoveHiddenBlockingMergeRequestsToBe = createHiddenInputExpectation(
        'input[name="merge_request[update_blocking_merge_request_refs]"]',
      );
      const makeComponentWithHiddenMrs = () => {
        const hiddenMrsRef = '2 inaccessible merge requests';
        createComponent({
          containsHiddenBlockingMrs: true,
          existingRefs: ['!1', '!2', hiddenMrsRef],
        });
      };

      it('is true when nothing has happened', () => {
        makeComponentWithHiddenMrs();

        expectRemoveHiddenBlockingMergeRequestsToBe(false);
      });

      it('is false when removing any other MRs', () => {
        makeComponentWithHiddenMrs();

        expectRemoveHiddenBlockingMergeRequestsToBe(false);
      });

      it('is false when ref has been removed', async () => {
        makeComponentWithHiddenMrs();
        removeRef(2);

        await nextTick();
        expectRemoveHiddenBlockingMergeRequestsToBe(true);
      });
    });
  });
});
