<script>
import {
  GlButton,
  GlTooltipDirective,
  GlCarousel,
  GlCarouselSlide,
  GlSprintf,
  GlLink,
} from '@gitlab/ui';
import securityDashboardImageUrl from 'ee_images/promotions/security-dashboard.png';
import securityDependencyImageUrl from 'ee_images/promotions/security-dependencies.png';
import securityScanningImageUrl from 'ee_images/promotions/security-scanning.png';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';
import HandRaiseLeadButton from 'ee/hand_raise_leads/hand_raise_lead/components/hand_raise_lead_button.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
    GlCarousel,
    GlCarouselSlide,
    GlSprintf,
    GlLink,
    HandRaiseLeadButton,
    GitlabExperiment,
  },
  mixins: [Tracking.mixin()],
  props: {
    project: {
      type: Object,
      required: false,
      default: null,
    },
    group: {
      type: Object,
      required: false,
      default: null,
    },
    linkMain: {
      type: String,
      required: false,
      default: '',
    },
    linkSecondary: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      slide: 0,
      carouselImages: [
        securityDependencyImageUrl,
        securityScanningImageUrl,
        securityDashboardImageUrl,
      ],
    };
  },
  computed: {
    discoverButtonProps() {
      return {
        variant: 'info',
        // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26
        // eslint-disable-next-line @gitlab/require-i18n-strings
        rel: 'noopener noreferrer',
        class: 'discover-button justify-content-center',
        'data-track-action': 'click_button',
      };
    },
  },
  methods: {
    onSlideStart(slide) {
      this.track('click_button', {
        label: 'security-discover-carousel',
        property: `sliding${this.slide}-${slide}`,
      });
    },
  },
  i18n: {
    discoverTitle: s__(
      'Discover|Security capabilities, integrated into your development lifecycle',
    ),
    discoverUpgradeLabel: s__('Discover|Upgrade now'),
    discoverTrialLabel: s__('Discover|Start a free trial'),
    carouselCaptions: [
      s__(
        'Discover|Check your application for security vulnerabilities that may lead to unauthorized access, data leaks, and denial of services.',
      ),
      s__(
        'Discover|GitLab will perform static and dynamic tests on the code of your application, looking for known flaws and report them in the merge request so you can fix them before merging.',
      ),
      s__(
        "Discover|For code that's already live in production, our dashboards give you an easy way to prioritize any issues that are found, empowering your team to ship quickly and securely.",
      ),
    ],
    discoverPlanCaption: s__(
      'Discover|See the other features of the %{linkStart}ultimate plan%{linkEnd}',
    ),
  },
};
</script>

<template>
  <div class="discover-box">
    <h2 class="discover-title gl-text-center gl-text-gray-900 gl-mx-auto">
      {{ $options.i18n.discoverTitle }}
    </h2>
    <div class="discover-carousels">
      <gl-carousel
        v-model="slide"
        class="discover-carousel discover-image-carousel gl-mx-auto gl-text-center gl-border-solid gl-border-1 gl-bg-gray-10 gl-border-gray-50"
        no-wrap
        controls
        :interval="0"
        indicators
        @sliding-start="onSlideStart"
      >
        <gl-carousel-slide
          v-for="(imageUrl, index) in carouselImages"
          :key="index"
          :img-src="imageUrl"
        />
      </gl-carousel>
      <gl-carousel
        ref="textCarousel"
        v-model="slide"
        class="discover-carousel discover-text-carousel gl-mx-auto gl-text-center"
        no-wrap
        :interval="0"
      >
        <gl-carousel-slide v-for="caption in $options.i18n.carouselCaptions" :key="caption">
          <template #img>
            {{ caption }}
          </template>
        </gl-carousel-slide>
      </gl-carousel>
      <div class="discover-footer gl-mx-auto gl-my-0">
        <p class="gl-text-gray-900 gl-text-center mb-7">
          <gl-sprintf :message="$options.i18n.discoverPlanCaption">
            <template #link="{ content }">
              <gl-link
                href="https://about.gitlab.com/pricing/saas/feature-comparison/"
                target="_blank"
              >
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </p>
      </div>
    </div>
    <div
      class="discover-buttons gl-display-flex gl-flex-direction-row gl-justify-content-space-between gl-mx-auto"
    >
      <gitlab-experiment name="pql_three_cta_test">
        <template #candidate>
          <hand-raise-lead-button />
        </template>
      </gitlab-experiment>
      <gl-button
        class="discover-button-upgrade gl-ml-3"
        v-bind="discoverButtonProps"
        category="secondary"
        data-track-label="security-discover-upgrade-cta"
        :data-track-property="slide"
        :href="linkSecondary"
      >
        {{ $options.i18n.discoverUpgradeLabel }}
      </gl-button>
      <gl-button
        class="discover-button-trial gl-ml-3"
        v-bind="discoverButtonProps"
        category="primary"
        data-track-label="security-discover-trial-cta"
        :data-track-property="slide"
        :href="linkMain"
      >
        {{ $options.i18n.discoverTrialLabel }}
      </gl-button>
    </div>
  </div>
</template>
