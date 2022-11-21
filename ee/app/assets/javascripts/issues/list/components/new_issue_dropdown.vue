<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { visitUrl } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';

export default {
  i18n: {
    newIssueLabel: __('New issue'),
    newObjectiveLabel: s__('WorkItem|New objective'),
  },
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  inject: ['newIssuePath'],
  data() {
    return {
      selectedOption: 'issue',
    };
  },
  computed: {
    dropdownText() {
      if (this.selectedOption === 'issue') {
        return this.$options.i18n.newIssueLabel;
      } else if (this.selectedOption === 'objective') {
        return this.$options.i18n.newObjectiveLabel;
      }

      return undefined;
    },
  },
  methods: {
    handleDropdownButtonClick() {
      if (this.selectedOption === 'issue') {
        visitUrl(this.newIssuePath);
      } else if (this.selectedOption === 'objective') {
        this.$emit('new-objective-clicked');
      }
    },
    handleDropdownItemClick(option) {
      this.selectedOption = option;
    },
  },
};
</script>

<template>
  <gl-dropdown
    right
    split
    :text="dropdownText"
    variant="confirm"
    @click="handleDropdownButtonClick()"
  >
    <gl-dropdown-item @click="handleDropdownItemClick('issue')">
      {{ $options.i18n.newIssueLabel }}
    </gl-dropdown-item>
    <gl-dropdown-item @click="handleDropdownItemClick('objective')">
      {{ $options.i18n.newObjectiveLabel }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
