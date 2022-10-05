<script>
import { GlFilteredSearch } from '@gitlab/ui';
import { AUDIT_FILTER_CONFIGS } from '../constants';
import { filterTokenOptionsValidator } from '../validators';

export default {
  components: {
    GlFilteredSearch,
  },
  props: {
    value: {
      type: Array,
      required: false,
      default: () => [],
    },
    filterTokenOptions: {
      type: Array,
      required: false,
      default: () => AUDIT_FILTER_CONFIGS,
      validator: filterTokenOptionsValidator,
    },
    viewOnly: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      filterTokens: this.filterTokenOptions.map((option) => ({
        ...AUDIT_FILTER_CONFIGS.find(({ type }) => type === option.type),
        ...option,
      })),
    };
  },
  computed: {
    tokenSearchTerm() {
      return this.value.find((term) => this.filterTokens.find((token) => token.type === term.type));
    },
    enabledTokens() {
      const { tokenSearchTerm } = this;

      // If a user has searched for a term within a token, limit the user to that one token
      if (tokenSearchTerm) {
        return this.filterTokens.map((token) => ({
          ...token,
          disabled: tokenSearchTerm.type !== token.type,
        }));
      }

      return this.filterTokens;
    },
  },
  methods: {
    onSubmit() {
      this.$emit('submit');
    },
    onInput(val) {
      this.$emit('selected', val);
    },
  },
};
</script>

<template>
  <div class="input-group bg-white flex-grow-1" data-testid="audit-events-filter">
    <gl-filtered-search
      :value="value"
      :placeholder="__('Search')"
      :clear-button-title="__('Clear')"
      :close-button-title="__('Close')"
      :available-tokens="enabledTokens"
      :view-only="viewOnly"
      class="gl-h-32 w-100"
      @submit="onSubmit"
      @input="onInput"
    />
  </div>
</template>
