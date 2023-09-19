<script>
import { GlModal } from '@gitlab/ui';
import { __ } from '~/locale';
import { LIMITED_ACCESS_MESSAGING } from './constants';

export default {
  name: 'LimitedAccessModal',
  components: { GlModal },
  props: {
    limitedAccessReason: {
      type: String,
      validator: (prop) => ['MANAGED_BY_RESELLER', 'RAMP_SUBSCRIPTION'].includes(prop),
      required: true,
    },
  },
  computed: {
    limitedAccessData() {
      return LIMITED_ACCESS_MESSAGING[this.limitedAccessReason];
    },
    modalTitle() {
      return this.limitedAccessData.title;
    },
    modalContent() {
      return this.limitedAccessData.content;
    },
    primaryAction() {
      return {
        text: __('Close'),
        attributes: { variant: 'confirm' },
      };
    },
  },
};
</script>
<template>
  <gl-modal
    :action-primary="primaryAction"
    modal-id="limited-access-modal-id"
    :title="modalTitle"
    data-testid="limited-access-modal-id"
  >
    {{ modalContent }}
  </gl-modal>
</template>
