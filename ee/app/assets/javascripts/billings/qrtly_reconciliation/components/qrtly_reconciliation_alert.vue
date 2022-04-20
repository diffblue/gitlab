<script>
import { GlAlert, GlSprintf } from '@gitlab/ui';
import Cookie from '~/lib/utils/cookies';
import { i18n } from 'ee/billings/qrtly_reconciliation/constants';
import { formatDate, getDayDifference } from '~/lib/utils/datetime_utility';
import { sprintf } from '~/locale';

export default {
  name: 'QrtlyReconciliationAlert',
  components: {
    GlAlert,
    GlSprintf,
  },
  props: {
    date: {
      type: Date,
      required: true,
    },
    cookieKey: {
      type: String,
      required: true,
    },
    usesNamespacePlan: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isAlertDismissed: false,
    };
  },
  computed: {
    alertTitle() {
      return sprintf(this.$options.i18n.title, { qrtlyDate: this.formattedDate });
    },
    formattedDate() {
      return formatDate(this.date, 'isoDate');
    },
    description() {
      return this.usesNamespacePlan
        ? this.$options.i18n.description.usesNamespacePlan
        : this.$options.i18n.description.ee;
    },
  },
  methods: {
    handleDismiss() {
      Cookie.set(this.cookieKey, true, {
        expires: getDayDifference(new Date(), new Date(this.date)),
      });
      this.isAlertDismissed = true;
    },
  },
  i18n,
};
</script>

<template>
  <gl-alert
    v-if="!isAlertDismissed"
    data-testid="qrtly-reconciliation-alert"
    variant="info"
    :title="alertTitle"
    :primary-button-text="$options.i18n.buttons.primary.text"
    :primary-button-link="$options.i18n.buttons.primary.link"
    :secondary-button-text="$options.i18n.buttons.secondary.text"
    :secondary-button-link="$options.i18n.buttons.secondary.link"
    @dismiss="handleDismiss"
  >
    <gl-sprintf :message="description">
      <template #qrtlyDate>
        <span>{{ formattedDate }}</span>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>
