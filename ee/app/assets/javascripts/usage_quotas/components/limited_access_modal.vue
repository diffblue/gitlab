<script>
import { GlModal } from '@gitlab/ui';
import { __, s__ } from '~/locale';

const LIMITED_ACCESS_MESSAGING = Object.freeze({
  MANAGED_BY_RESELLER: {
    title: s__('SubscriptionMangement|Your subscription is in read-only mode'),
    content: s__(
      'SubscriptionMangement|To make changes to a read-only subscription or purchase additional products, contact your GitLab Partner.',
    ),
  },
  RAMP_SUBSCRIPTION: {
    title: s__(
      'SubscriptionMangement|This is a custom subscription managed by the GitLab Sales team',
    ),
    content: s__(
      "SubscriptionMangement|If you'd like to add more seats, upgrade your plan, or purchase additional products, contact your GitLab sales representative.",
    ),
  },
});

export default {
  name: 'LimitedAccessModal',
  components: { GlModal },
  props: {
    limitedAccessReason: {
      type: String,
      // defaults to 'MANAGED_BY_RESELLER' till we have API wired
      default: 'MANAGED_BY_RESELLER',
      validator: (prop) => ['MANAGED_BY_RESELLER', 'RAMP_SUBSCRIPTION'].includes(prop),
      required: false,
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
