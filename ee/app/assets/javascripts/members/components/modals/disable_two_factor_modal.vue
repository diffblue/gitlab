<script>
import { GlModal } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import csrf from '~/lib/utils/csrf';
import {
  DISABLE_TWO_FACTOR_MODAL_ID,
  I18N_CANCEL,
  I18N_DISABLE,
  I18N_DISABLE_TWO_FACTOR_MODAL_TITLE,
} from '../../constants';

export default {
  actionCancel: {
    text: I18N_CANCEL,
  },
  actionPrimary: {
    text: I18N_DISABLE,
    attributes: {
      variant: 'danger',
    },
  },
  modalId: DISABLE_TWO_FACTOR_MODAL_ID,
  title: I18N_DISABLE_TWO_FACTOR_MODAL_TITLE,
  csrf,
  components: {
    GlModal,
  },
  inject: ['namespace'],
  computed: {
    ...mapState({
      disableTwoFactorPath(state) {
        return state[this.namespace].disableTwoFactorPath;
      },
      isVisible(state) {
        return state[this.namespace].disableTwoFactorModalVisible;
      },
      message(state) {
        return state[this.namespace].disableTwoFactorModalData?.message;
      },
      userId(state) {
        return state[this.namespace].disableTwoFactorModalData?.userId;
      },
    }),
  },
  methods: {
    ...mapActions({
      hideDisableTwoFactorModal(dispatch) {
        return dispatch(`${this.namespace}/hideDisableTwoFactorModal`);
      },
    }),
    submitForm() {
      this.$refs.form.submit();
    },
  },
};
</script>

<template>
  <gl-modal
    v-bind="$attrs"
    :modal-id="$options.modalId"
    :action-cancel="$options.actionCancel"
    :action-primary="$options.actionPrimary"
    :title="$options.title"
    :visible="isVisible"
    @primary="submitForm"
    @hide="hideDisableTwoFactorModal"
  >
    <form ref="form" :action="disableTwoFactorPath" method="post">
      <p>{{ message }}</p>
      <input ref="method" type="hidden" name="_method" value="delete" />
      <input type="hidden" name="user_id" :value="userId" />
      <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    </form>
  </gl-modal>
</template>
