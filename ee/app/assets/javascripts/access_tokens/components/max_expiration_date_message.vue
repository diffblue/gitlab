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
            helpPagePath('user/admin_area/settings/account_and_limit_settings', {
              anchor: 'limit-the-lifetime-of-personal-access-tokens',
            })
          "
          target="_blank"
          >{{ content }}</gl-link
        ></template
      >
    </gl-sprintf>
  </span>
</template>
