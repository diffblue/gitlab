<script>
import { GlFormGroup } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import ConfirmDanger from '~/vue_shared/components/confirm_danger/confirm_danger.vue';
import NamespaceSelect from '~/vue_shared/components/namespace_select/namespace_select.vue';

export default {
  name: 'TransferGroupForm',
  components: {
    ConfirmDanger,
    GlFormGroup,
    NamespaceSelect,
  },
  props: {
    parentGroups: {
      type: Object,
      required: true,
    },
    isDisabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    confirmationPhrase: {
      type: String,
      required: true,
    },
    confirmButtonText: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      selectedId: null,
    };
  },
  computed: {
    selectedNamespaceId() {
      return this.selectedId;
    },
  },
  methods: {
    handleSelected({ id }) {
      this.selectedId = id;
    },
  },
  i18n: {
    dropdownTitle: s__('GroupSettings|Select parent group'),
    emptyNamespaceTitle: __('No parent group'),
  },
};
</script>
<template>
  <div>
    <gl-form-group>
      <namespace-select
        data-qa-selector="select_group_dropdown"
        :default-text="$options.i18n.dropdownTitle"
        :data="parentGroups"
        :empty-namespace-title="$options.i18n.emptyNamespaceTitle"
        include-empty-namespace
        include-headers
        @select="handleSelected"
      />
      <input
        id="new_parent_group_id"
        type="hidden"
        name="new_parent_group_id"
        :value="selectedId"
      />
      <confirm-danger
        button-class="qa-transfer-button"
        :disabled="isDisabled"
        :phrase="confirmationPhrase"
        :button-text="confirmButtonText"
        @confirm="$emit('confirm')"
      />
    </gl-form-group>
  </div>
</template>
