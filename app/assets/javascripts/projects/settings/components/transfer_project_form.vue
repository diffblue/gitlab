<script>
import { GlFormGroup } from '@gitlab/ui';
import { __ } from '~/locale';
import NamespaceSelect from '~/vue_shared/components/namespace_select.vue';
import ConfirmDanger from '~/vue_shared/components/confirm_danger/confirm_danger.vue';

export default {
  name: 'TransferProjectForm',
  components: {
    GlFormGroup,
    NamespaceSelect,
    ConfirmDanger,
  },
  props: {
    namespaces: {
      type: Object,
      required: true,
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
    return { selectedNamespace: null };
  },
  computed: {
    hasSelectedNamespace() {
      return Boolean(this.selectedNamespace?.humanName);
    },
    dropdownText() {
      return this.selectedNamespace?.humanName || this.$options.i18n.defaultText;
    },
  },
  methods: {
    handleSelect(selectedNamespace) {
      this.selectedNamespace = selectedNamespace;
      this.$emit('selectNamespace', selectedNamespace.id);
    },
  },
  i18n: {
    defaultText: __('Select a namespace'),
  },
};
</script>
<template>
  <div>
    <gl-form-group>
      <namespace-select
        data-testid="transfer-project-namespace"
        :full-width="true"
        :data="namespaces"
        :dropdown-text="dropdownText"
        @select="handleSelect"
      />
    </gl-form-group>
    <confirm-danger
      :disabled="!hasSelectedNamespace"
      :phrase="confirmationPhrase"
      :button-text="confirmButtonText"
      @confirm="$emit('confirm')"
    />
  </div>
</template>
