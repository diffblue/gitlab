<script>
import {
  GlButton,
  GlTooltipDirective,
  GlCarousel,
  GlCarouselSlide,
  GlSprintf,
  GlLink,
  GlModalDirective,
} from '@gitlab/ui';
import { DISCOVER_PLANS_MORE_INFO_LINK } from 'jh_else_ee/vue_shared/discover/constants';
import securityDashboardImageUrl from 'ee_images/promotions/security-dashboard.png';
import securityDependencyImageUrl from 'ee_images/promotions/security-dependencies.png';
import securityScanningImageUrl from 'ee_images/promotions/security-scanning.png';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import MovePersonalProjectToGroupModal from 'ee/projects/components/move_personal_project_to_group_modal.vue';
import { MOVE_PERSONAL_PROJECT_TO_GROUP_MODAL } from 'ee/projects/constants';

export default {
  DISCOVER_PLANS_MORE_INFO_LINK,
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModalDirective,
  },
  components: {
    GlButton,
    GlCarousel,
    GlCarouselSlide,
    GlSprintf,
    GlLink,
    MovePersonalProjectToGroupModal,
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
        class: 'gl-ml-3',
        variant: 'info',
        // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26
        // eslint-disable-next-line @gitlab/require-i18n-strings
        rel: 'noopener noreferrer',
        'data-track-action': 'click_button',
        'data-track-property': this.slide,
      };
    },
    upgradeButtonProps() {
      return {
        category: 'secondary',
        'data-testid': 'discover-button-upgrade',
        'data-track-label': 'security-discover-upgrade-cta',

        ...this.discoverButtonProps,
      };
    },
    trialButtonProps() {
      return {
        category: 'primary',
        'data-testid': 'discover-button-trial',
        'data-track-label': 'security-discover-trial-cta',
        ...this.discoverButtonProps,
      };
    },
    isPersonalProject() {
      return this.project.isPersonal;
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
  modalId: MOVE_PERSONAL_PROJECT_TO_GROUP_MODAL,
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
              <gl-link :href="$options.DISCOVER_PLANS_MORE_INFO_LINK" target="_blank">
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </p>
      </div>
    </div>
    <div class="gl-display-flex gl-flex-direction-row gl-justify-content-center gl-mx-auto">
      <template v-if="isPersonalProject">
        <gl-button v-gl-modal-directive="$options.modalId" v-bind="upgradeButtonProps">
          {{ $options.i18n.discoverUpgradeLabel }}
        </gl-button>

        <gl-button v-gl-modal-directive="$options.modalId" v-bind="trialButtonProps">
          {{ $options.i18n.discoverTrialLabel }}
        </gl-button>

        <move-personal-project-to-group-modal :project-name="project.name" />
      </template>

      <template v-else>
        <gl-button v-bind="upgradeButtonProps" :href="linkSecondary">
          {{ $options.i18n.discoverUpgradeLabel }}
        </gl-button>

        <gl-button v-bind="trialButtonProps" :href="linkMain">
          {{ $options.i18n.discoverTrialLabel }}
        </gl-button>
      </template>
    </div>
  </div>
</template>
