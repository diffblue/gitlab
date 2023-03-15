<script>
import { GlCard, GlIcon, GlPopover, GlLink } from '@gitlab/ui';
import { mapGetters } from 'vuex';
import { HELP_INFO_URL } from 'ee/geo_sites/constants';
import { s__, __ } from '~/locale';
import GeoSiteProgressBar from '../geo_site_progress_bar.vue';

export default {
  name: 'GeoSiteVerificationInfo',
  i18n: {
    verificationInfo: s__('Geo|Verification information'),
    replicationHelpText: s__(
      'Geo|Replicated data is verified with the secondary site(s) using checksums.',
    ),
    learnMore: __('Learn more'),
    progressBarTitle: s__('Geo|%{title} checksum progress'),
    checksummed: s__('Geo|Checksummed'),
    nothingToChecksum: s__('Geo|Nothing to checksum'),
  },
  components: {
    GlCard,
    GlIcon,
    GlPopover,
    GlLink,
    GeoSiteProgressBar,
  },
  props: {
    site: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapGetters(['verificationInfo']),
    verificationInfoBars() {
      return this.verificationInfo(this.site.id);
    },
  },
  HELP_INFO_URL,
};
</script>

<template>
  <gl-card header-class="gl-display-flex gl-align-items-center">
    <template #header>
      <h5 class="gl-my-0">{{ $options.i18n.verificationInfo }}</h5>
      <gl-icon
        ref="verificationInfo"
        name="question-o"
        class="gl-text-blue-600 gl-cursor-pointer gl-ml-2"
      />
      <gl-popover
        :target="() => $refs.verificationInfo && $refs.verificationInfo.$el"
        placement="top"
        triggers="hover focus"
      >
        <p class="gl-font-base">
          {{ $options.i18n.replicationHelpText }}
        </p>
        <gl-link :href="$options.HELP_INFO_URL" target="_blank">{{
          $options.i18n.learnMore
        }}</gl-link>
      </gl-popover>
    </template>
    <div v-for="bar in verificationInfoBars" :key="bar.title" class="gl-mb-5">
      <span data-testid="verification-bar-title">{{
        sprintf($options.i18n.progressBarTitle, { title: bar.title })
      }}</span>
      <geo-site-progress-bar
        class="gl-mt-3"
        :title="
          /* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */
          sprintf($options.i18n.progressBarTitle, {
            title: bar.title,
          }) /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */
        "
        :values="bar.values"
        :success-label="$options.i18n.checksummed"
        :unavailable-label="$options.i18n.nothingToChecksum"
      />
    </div>
  </gl-card>
</template>
