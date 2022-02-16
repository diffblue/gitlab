<script>
import { uniqueId } from 'lodash';
import { GlButton, GlModal, GlModalDirective, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import csrf from '~/lib/utils/csrf';

export default {
  components: {
    GlButton,
    GlModal,
    GlSprintf,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  inject: {
    name: {
      default: '',
    },
    path: {
      default: '',
    },
  },
  data() {
    return {
      modalId: uniqueId('application-delete-button-'),
    };
  },
  methods: {
    deleteApplication() {
      this.$refs.deleteForm.submit();
    },
  },
  i18n: {
    destroy: __('Destroy'),
    title: __('Confirm destroy application'),
    body: __('Are you sure that you want to destroy %{application}'),
  },
  modal: {
    actionPrimary: {
      text: __('Destroy'),
      attributes: {
        variant: 'danger',
      },
    },
    actionSecondary: {
      text: __('Cancel'),
      attributes: {
        variant: 'default',
      },
    },
  },
  csrf,
};
</script>
<template>
  <div>
    <gl-button v-gl-modal="modalId" variant="danger">{{ $options.i18n.destroy }}</gl-button>
    <gl-modal
      :title="$options.i18n.title"
      :action-primary="$options.modal.actionPrimary"
      :action-secondary="$options.modal.actionSecondary"
      :modal-id="modalId"
      size="sm"
      @primary="deleteApplication"
      ><gl-sprintf :message="$options.i18n.body">
        <template #application>
          <strong>{{ name }}</strong>
        </template></gl-sprintf
      >
      <form ref="deleteForm" method="post" :action="path">
        <input type="hidden" name="_method" value="delete" />
        <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />
      </form>
    </gl-modal>
  </div>
</template>
