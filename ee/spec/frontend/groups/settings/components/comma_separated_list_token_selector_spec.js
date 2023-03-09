import { GlToken, GlTokenSelector } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';

import CommaSeparatedListTokenSelector from 'ee/groups/settings/components/comma_separated_list_token_selector.vue';

describe('CommaSeparatedListTokenSelector', () => {
  let wrapper;
  let div;
  let input;

  const defaultProps = {
    hiddenInputId: 'comma-separated-list',
    ariaLabelledby: 'comma-separated-list-label',
    regexErrorMessage: 'The value entered is invalid',
    disallowedValueErrorMessage: 'The value entered is not allowed',
  };

  const createComponent = (options) => {
    wrapper = mount(CommaSeparatedListTokenSelector, {
      attachTo: div,
      scopedSlots: {
        'user-defined-token-content': '<span>Add "{{props.inputText}}"</span>',
      },
      ...options,
      propsData: {
        ...defaultProps,
        ...(options?.propsData || {}),
      },
    });
  };

  const findTokenSelector = () => wrapper.findComponent(GlTokenSelector);

  const findTokenSelectorInput = () => findTokenSelector().find('input[type="text"]');

  const findTokenSelectorDropdown = () => findTokenSelector().find('[role="menu"]');

  const findErrorMessageText = () =>
    findTokenSelector().find('[role="menuitem"][disabled="disabled"]').text();

  const setTokenSelectorInputValue = (value) => {
    const tokenSelectorInput = findTokenSelectorInput();

    tokenSelectorInput.element.value = value;
    tokenSelectorInput.trigger('input');

    return nextTick();
  };

  const tokenSelectorTriggerEnter = (event) => {
    const tokenSelectorInput = findTokenSelectorInput();
    tokenSelectorInput.trigger('keydown.enter', event);
  };

  beforeEach(() => {
    div = document.createElement('div');
    input = document.createElement('input');
    input.setAttribute('type', 'text');
    input.id = 'comma-separated-list';
    document.body.appendChild(div);
    document.body.appendChild(input);
  });

  afterEach(() => {
    div.remove();
    input.remove();
  });

  describe('when component is mounted', () => {
    it.each`
      inputValue                                 | expectedTokens
      ${'gitlab.com,gitlab.org,gitlab.ninja'}    | ${['gitlab.com', 'gitlab.org', 'gitlab.ninja']}
      ${'gitlab.com, gitlab.org,  gitlab.ninja'} | ${['gitlab.com', 'gitlab.org', 'gitlab.ninja']}
      ${'foo bar, baz'}                          | ${['foo bar', 'baz']}
      ${'192.168.0.0/24,192.168.1.0/24'}         | ${['192.168.0.0/24', '192.168.1.0/24']}
    `(
      'parses comma separated list ($inputValue) into tokens',
      async ({ inputValue, expectedTokens }) => {
        input.value = inputValue;
        createComponent();

        await nextTick();

        wrapper.findAllComponents(GlToken).wrappers.forEach((tokenWrapper, index) => {
          expect(tokenWrapper.text()).toBe(expectedTokens[index]);
        });
      },
    );
  });

  describe('when selected tokens changes', () => {
    const setup = () => {
      const tokens = [
        {
          id: 1,
          name: 'gitlab.com',
        },
        {
          id: 2,
          name: 'gitlab.org',
        },
        {
          id: 3,
          name: 'gitlab.ninja',
        },
      ];

      createComponent();
      findTokenSelector().vm.$emit('input', tokens);
    };

    it('sets input value', async () => {
      await setup();

      expect(input.value).toBe('gitlab.com,gitlab.org,gitlab.ninja');
    });

    it('fires `input` event', async () => {
      const dispatchEvent = jest.spyOn(input, 'dispatchEvent');
      await setup();

      expect(dispatchEvent).toHaveBeenCalledWith(
        new Event('input', {
          bubbles: true,
          cancelable: true,
        }),
      );
    });
  });

  describe('when text input is typed in', () => {
    it('emits `text-input` event', async () => {
      createComponent();

      await setTokenSelectorInputValue('foo bar');

      expect(wrapper.emitted('text-input')[0]).toEqual(['foo bar']);
    });
  });

  describe('when enter key is pressed', () => {
    it('does not submit the form if token selector text input has a value', async () => {
      createComponent();

      await setTokenSelectorInputValue('foo bar');

      const event = { preventDefault: jest.fn() };
      tokenSelectorTriggerEnter(event);

      expect(event.preventDefault).toHaveBeenCalled();
    });

    describe('when `regexValidator` prop is set', () => {
      it('displays `regexErrorMessage` if regex fails', async () => {
        createComponent({
          propsData: {
            regexValidator: /baz/,
          },
        });

        await setTokenSelectorInputValue('foo bar');

        tokenSelectorTriggerEnter();

        expect(findErrorMessageText()).toBe('The value entered is invalid');
      });
    });

    describe('when `disallowedValues` prop is set', () => {
      it('displays `disallowedValueErrorMessage` if value is in the disallowed list', async () => {
        createComponent({
          propsData: {
            disallowedValues: ['foo', 'bar', 'baz'],
          },
        });

        await setTokenSelectorInputValue('foo');

        tokenSelectorTriggerEnter();

        expect(findErrorMessageText()).toBe('The value entered is not allowed');
      });
    });

    describe('when `customErrorMessage` prop is set', () => {
      it('displays `customErrorMessage`', () => {
        createComponent({
          propsData: {
            customErrorMessage: 'Value is invalid',
          },
        });

        tokenSelectorTriggerEnter();

        expect(findErrorMessageText()).toBe('Value is invalid');
      });
    });

    describe('when `regexValidator`, `disallowedValues` and `customErrorMessage` props are set', () => {
      it('displays `regexErrorMessage` if regex fails', async () => {
        createComponent({
          propsData: {
            regexValidator: /baz/,
            disallowedValues: ['foo', 'bar', 'baz'],
          },
        });

        await setTokenSelectorInputValue('foo bar');

        tokenSelectorTriggerEnter();

        expect(findErrorMessageText()).toBe('The value entered is invalid');
      });

      it('displays `disallowedValueErrorMessage` if regex passes but value is in the disallowed list', async () => {
        createComponent({
          propsData: {
            regexValidator: /foo/,
            disallowedValues: ['foo', 'bar', 'baz'],
          },
        });

        await setTokenSelectorInputValue('foo');

        tokenSelectorTriggerEnter();

        expect(findErrorMessageText()).toBe('The value entered is not allowed');
      });

      it('displays `customErrorMessage` if regex passes and value is not in the disallowed list', async () => {
        createComponent({
          propsData: {
            regexValidator: /foo bar/,
            disallowedValues: ['foo', 'bar', 'baz'],
            customErrorMessage: 'Value is invalid',
          },
        });

        await setTokenSelectorInputValue('foo bar');

        tokenSelectorTriggerEnter();

        expect(findErrorMessageText()).toBe('Value is invalid');
      });
    });
  });

  describe('when `regexValidator` and `disallowedValues` props are set', () => {
    it('allows value to be added as a token if regex passes and value is not in the disallowed list', async () => {
      createComponent({
        propsData: {
          regexValidator: /foo/,
          disallowedValues: ['bar', 'baz'],
        },
      });

      await setTokenSelectorInputValue('foo');

      expect(findTokenSelectorDropdown().text()).toBe('Add "foo"');
    });
  });

  describe('when `regexValidator`, `disallowedValues` and `customErrorMessage` props are not set', () => {
    it('allows any value to be added', async () => {
      createComponent();

      await setTokenSelectorInputValue('foo');

      expect(findTokenSelectorDropdown().text()).toBe('Add "foo"');
    });
  });

  describe('when token selector text input is typed in after showing error message', () => {
    it('hides error message', async () => {
      createComponent({
        propsData: {
          regexValidator: /baz/,
        },
      });

      await setTokenSelectorInputValue('foo');

      tokenSelectorTriggerEnter();

      expect(findErrorMessageText()).toBe('The value entered is invalid');

      await setTokenSelectorInputValue('foo bar');

      await nextTick();

      expect(findTokenSelectorDropdown().classes()).not.toContain('show');
    });
  });

  describe('when token selector text input is blurred after showing error message', () => {
    it('hides error message', async () => {
      createComponent({
        propsData: {
          regexValidator: /baz/,
        },
      });

      await setTokenSelectorInputValue('foo');

      tokenSelectorTriggerEnter();

      findTokenSelectorInput().trigger('blur');

      await nextTick();

      expect(findTokenSelectorDropdown().classes()).not.toContain('show');
    });
  });
});
