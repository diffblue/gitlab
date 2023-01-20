<script>
import { GlDisclosureDropdown } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'HookTestDropdown',
  components: {
    GlDisclosureDropdown,
  },
  props: {
    items: {
      type: Array,
      required: true,
    },
    size: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  computed: {
    itemsWithAction() {
      return this.items.map((item) => ({
        text: item.text,
        action: () => this.testHook(item.href),
      }));
    },
  },
  methods: {
    testHook(href) {
      const a = document.createElement('a');
      a.setAttribute('hidden', '');
      a.href = href;
      a.dataset.method = 'post';
      document.body.appendChild(a);
      a.click();
      a.remove();
    },
  },
  i18n: {
    test: __('Test'),
  },
};
</script>

<template>
  <gl-disclosure-dropdown :toggle-text="$options.i18n.test" :items="itemsWithAction" :size="size" />
</template>
