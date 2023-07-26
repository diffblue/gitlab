<script>
import { GlSprintf, GlLink } from '@gitlab/ui';

import { __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { formatDate } from '~/lib/utils/datetime_utility';

export default {
  i18n: {
    message: __(
      'An Administrator has set the maximum expiration date to %{maxDate}. %{helpLinkStart}Learn more%{helpLinkEnd}.',
    ),
  },
  components: { GlSprintf, GlLink },
  props: {
    maxDate: {
      type: Date,
      required: false,
      default: () => null,
    },
  },
  computed: {
    formattedMaxDate() {
      if (!this.maxDate) {
        return '';
      }

      return formatDate(this.maxDate, 'isoDate');
    },
  },
  methods: { helpPagePath },
};
</script>

<template>
  <span v-if="maxDate">
    <gl-sprintf :message="$options.i18n.message">
      <template #maxDate>{{ formattedMaxDate }}</template>
      <template #helpLink="{ content }"
        ><gl-link
          :href="
            /* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */
            helpPagePath('administration/settings/account_and_limit_settings', {
              anchor: 'limit-the-lifetime-of-access-tokens',
            }) /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */
          "
          target="_blank"
          >{{ content }}</gl-link
        ></template
      >
    </gl-sprintf>
  </span>
</template>
