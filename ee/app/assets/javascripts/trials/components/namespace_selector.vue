<script>
import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import ListboxInput from '~/vue_shared/components/listbox_input/listbox_input.vue';
import { __ } from '~/locale';

export const CREATE_GROUP_OPTION_VALUE = '0';

export default {
  i18n: {
    groupSelectLabel: __('This subscription is for'),
    defaultToggleText: __('Please select a group'),
    newGroupNameLabel: __('New Group Name'),
  },
  components: { GlFormGroup, GlFormInput, ListboxInput },
  props: {
    items: {
      type: Array,
      required: true,
    },
    initialValue: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      selectedGroup: this.initialValue,
    };
  },
  computed: {
    showNewGroupNameField() {
      return this.selectedGroup === CREATE_GROUP_OPTION_VALUE;
    },
  },
};
</script>

<template>
  <div>
    <listbox-input
      v-model="selectedGroup"
      name="namespace_id"
      data-qa-selector="subscription_for"
      :label="$options.i18n.groupSelectLabel"
      :items="items"
      :default-toggle-text="$options.i18n.defaultToggleText"
    />
    <gl-form-group v-if="showNewGroupNameField" :label="$options.i18n.newGroupNameLabel">
      <gl-form-input
        name="new_group_name"
        data-qa-selector="new_group_name"
        data-testid="new-group-name-input"
        required
      />
    </gl-form-group>
  </div>
</template>
