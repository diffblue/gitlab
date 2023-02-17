<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { TYPE_ISSUE } from '~/issues/constants';
import { visitUrl } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';

export default {
  TYPE_ISSUE,
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
      selectedOption: TYPE_ISSUE,
    };
  },
  computed: {
    dropdownText() {
      if (this.selectedOption === TYPE_ISSUE) {
        return this.$options.i18n.newIssueLabel;
      } else if (this.selectedOption === 'objective') {
        return this.$options.i18n.newObjectiveLabel;
      }

      return undefined;
    },
  },
  methods: {
    handleDropdownButtonClick() {
      if (this.selectedOption === TYPE_ISSUE) {
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
    <gl-dropdown-item @click="handleDropdownItemClick($options.TYPE_ISSUE)">
      {{ $options.i18n.newIssueLabel }}
    </gl-dropdown-item>
    <gl-dropdown-item @click="handleDropdownItemClick('objective')">
      {{ $options.i18n.newObjectiveLabel }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
