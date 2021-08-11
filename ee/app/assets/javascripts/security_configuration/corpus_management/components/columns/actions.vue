<script>
import { GlButton, GlModal, GlModalDirective } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlButton,
    GlModal,
  },
  directives: {
    GlModalDirective,
  },
  props: {
    corpus: {
      type: Object,
      required: true,
    },
  },
  i18n: {
    deleteCorpusMessage: s__('Corpus Management|Are you sure you want to delete the corpus?'),
  },
  modal: {
    actionPrimary: {
      text: s__('Delete corpus'),
      attributes: { variant: 'danger', 'data-testid': 'modal-confirm' },
    },
    actionCancel: {
      text: s__('Cancel'),
    },
  },
  computed: {
    downloadPath() {
      /*
       * TODO: Replace with relative path when we complete backend
       * https://gitlab.com/gitlab-org/gitlab/-/issues/321618
       */
      return `https://www.gitlab.com/${this.corpus.downloadPath}`;
    },
  },
};
</script>
<template>
  <span>
    <gl-button class="gl-mr-2" icon="download" :href="downloadPath" />
    <gl-button
      v-gl-modal-directive="`confirmation-modal-${corpus.name}`"
      icon="remove"
      category="secondary"
      variant="danger"
    />

    <gl-modal
      header-class="gl-border-b-initial"
      body-class="gl-display-none"
      size="sm"
      :title="$options.i18n.deleteCorpusMessage"
      :modal-id="`confirmation-modal-${corpus.name}`"
      :action-primary="$options.modal.actionPrimary"
      :action-cancel="$options.modal.actionCancel"
      @primary="$emit('delete', corpus)"
    />
  </span>
</template>
