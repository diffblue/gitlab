<script>
import { GlModal } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';

const I18N_TITLE = s__('Artifacts|Delete %{name}?');
const I18N_BODY = s__(
  'Artifacts|This artifact will be permanently deleted. Any reports generated from this artifact will be empty.',
);
const I18N_PRIMARY = s__('Artifacts|Delete artifact');
const I18N_CANCEL = __('Cancel');

export default {
  components: {
    GlModal,
  },
  props: {
    artifactName: {
      type: String,
      required: true,
    },
    deleting: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    title() {
      return sprintf(I18N_TITLE, { name: this.artifactName });
    },
    actionPrimary() {
      return { text: I18N_PRIMARY, attributes: { variant: 'danger', loading: this.deleting } };
    },
  },
  actionCancel: { text: I18N_CANCEL },
  I18N_BODY,
};
</script>

<template>
  <gl-modal
    ref="modal"
    modal-id="artifact-delete-modal"
    size="sm"
    :title="title"
    :action-primary="actionPrimary"
    :action-cancel="$options.actionCancel"
    v-bind="$attrs"
    v-on="$listeners"
  >
    {{ $options.I18N_BODY }}
  </gl-modal>
</template>
