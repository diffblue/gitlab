<script>
import { GlAlert, GlFormGroup, GlLink, GlSprintf } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import ConfirmDanger from '~/vue_shared/components/confirm_danger/confirm_danger.vue';
import NamespaceSelect from '~/vue_shared/components/namespace_select/namespace_select.vue';

export const i18n = {
  emptyNamespaceTitle: __('No parent group'),
  dropdownTitle: s__('GroupSettings|Select parent group'),
  paidGroupMessage: s__(
    "GroupSettings|This group can't be transfered because it is linked to a subscription. To transfer this group, %{linkStart}link the subscription%{linkEnd} with a different group.",
  ),
};

export default {
  name: 'TransferGroupForm',
  components: {
    ConfirmDanger,
    GlAlert,
    GlFormGroup,
    GlLink,
    GlSprintf,
    NamespaceSelect,
  },
  props: {
    parentGroups: {
      type: Object,
      required: true,
    },
    isPaidGroup: {
      type: Boolean,
      required: true,
    },
    paidGroupHelpLink: {
      type: String,
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
    disableSubmitButton() {
      return this.isDisabled || !this.selectedId;
    },
  },
  methods: {
    handleSelected({ id }) {
      this.selectedId = id;
    },
  },
  i18n,
};
</script>
<template>
  <div>
    <gl-form-group>
      <namespace-select
        :default-text="$options.i18n.dropdownTitle"
        :data="parentGroups"
        :empty-namespace-title="$options.i18n.emptyNamespaceTitle"
        :include-headers="false"
        include-empty-namespace
        @select="handleSelected"
      />
      <input type="hidden" name="new_parent_group_id" :value="selectedId" />
    </gl-form-group>
    <gl-alert v-if="isPaidGroup" class="gl-mb-5">
      <gl-sprintf :message="$options.i18n.paidGroupMessage">
        <template #link="{ content }">
          <gl-link :href="paidGroupHelpLink">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>
    <confirm-danger
      button-class="qa-transfer-button"
      :disabled="disableSubmitButton"
      :phrase="confirmationPhrase"
      :button-text="confirmButtonText"
      @confirm="$emit('confirm')"
    />
  </div>
</template>
