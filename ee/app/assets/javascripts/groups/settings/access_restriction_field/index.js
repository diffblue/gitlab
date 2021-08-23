import Vue from 'vue';
import { __, sprintf } from '~/locale';
import CommaSeparatedListTokenSelector from '../components/comma_separated_list_token_selector.vue';

export default ({ selector, props = {}, qaSelector, customValidator = null }) => {
  const el = document.querySelector(selector);

  if (!el) return;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      CommaSeparatedListTokenSelector,
    },
    data() {
      const { hiddenInputId, labelId, regexValidator, disallowedValues } = el.dataset;

      return {
        hiddenInputId,
        labelId,
        regexValidator,
        ...(regexValidator ? { regexValidator: new RegExp(regexValidator) } : {}),
        ...(disallowedValues ? { disallowedValues: JSON.parse(disallowedValues) } : {}),
        customErrorMessage: '',
      };
    },
    methods: {
      handleTextInput(value) {
        this.customErrorMessage = customValidator(value);
      },
    },
    render(createElement) {
      return createElement('comma-separated-list-token-selector', {
        attrs: {
          'data-qa-selector': qaSelector,
        },
        props: {
          hiddenInputId: this.hiddenInputId,
          ariaLabelledby: this.labelId,
          regexValidator: this.regexValidator,
          disallowedValues: this.disallowedValues,
          customErrorMessage: this.customErrorMessage,
          ...props,
        },
        on: customValidator ? { 'text-input': this.handleTextInput } : {},
        scopedSlots: {
          'user-defined-token-content': ({ inputText: value }) => {
            return sprintf(__('Add "%{value}"'), { value });
          },
        },
      });
    },
  });
};
