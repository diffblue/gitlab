<script>
import { GlButtonGroup, GlButton, GlDisclosureDropdown } from '@gitlab/ui';
import { __, s__ } from '~/locale';

export default {
  i18n: {
    newIssueLabel: __('New issue'),
    newObjectiveLabel: s__('WorkItem|New objective'),
    toggleSrText: __('Issue type'),
  },
  components: {
    GlDisclosureDropdown,
    GlButton,
    GlButtonGroup,
  },
  inject: ['newIssuePath'],
  computed: {
    items() {
      return [
        {
          text: this.$options.i18n.newIssueLabel,
          href: this.newIssuePath,
        },
        {
          text: this.$options.i18n.newObjectiveLabel,
          action: () => {
            this.$emit('new-objective-clicked');
          },
        },
      ];
    },
  },
};
</script>

<template>
  <!--TODO: Replace button-group workaround once `split` option for new dropdowns is implemented.-->
  <!-- See issue at https://gitlab.com/gitlab-org/gitlab-ui/-/issues/2263-->
  <gl-button-group>
    <gl-button variant="confirm" :href="newIssuePath">
      {{ $options.i18n.newIssueLabel }}
    </gl-button>
    <gl-disclosure-dropdown
      :toggle-text="$options.i18n.toggleSrText"
      placement="right"
      class="split"
      toggle-class="gl-rounded-top-left-none! gl-rounded-bottom-left-none! gl-pl-2!"
      text-sr-only
      variant="confirm"
      :items="items"
    />
  </gl-button-group>
</template>
