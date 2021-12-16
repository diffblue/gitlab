<script>
import { GlAccordion, GlAccordionItem, GlButton, GlLink } from '@gitlab/ui';

export default {
  components: {
    GlAccordion,
    GlAccordionItem,
    GlButton,
    GlLink,
  },
  inject: ['learnMorePath', 'promoImageAlt', 'promoImagePath', 'tryNowPath'],
};
</script>

<template>
  <div class="gl-mt-2">
    <p class="gl-mb-0 gl-text-gray-500">
      {{ __('Approvals are optional.') }}
    </p>

    <gl-accordion :header-level="3">
      <gl-accordion-item :title="s__('ApprovalRule|Approval rules')" visible>
        <h4 class="gl-font-base gl-line-height-20 gl-mt-5 gl-mb-3">
          {{ s__('ApprovalRule|Add required approvers to improve your code review process') }}
        </h4>
        <div class="gl-display-flex">
          <div class="gl-flex-grow-1 gl-max-w-62 gl-mr-5">
            <ul class="gl-list-style-position-inside gl-p-0 gl-mb-3">
              <li>{{ s__('ApprovalRule|Assign approvers by area of expertise.') }}</li>
              <li>{{ s__('ApprovalRule|Increase your organization’s code quality.') }}</li>
              <li>{{ s__('ApprovalRule|Reduce the overall time to merge.') }}</li>
              <li>
                {{
                  s__(
                    'ApprovalRule|Let GitLab designate eligible approvers based on the files changed.',
                  )
                }}
              </li>
            </ul>
            <p>
              <gl-link :href="learnMorePath" target="_blank">
                {{ s__('ApprovalRule|Learn more about merge request approval.') }}
              </gl-link>
            </p>
            <gl-button category="primary" variant="confirm" :href="tryNowPath" target="_blank">{{
              s__('ApprovalRule|Try it for free')
            }}</gl-button>
          </div>
          <div class="gl-flex-grow-0 gl-max-w-26 gl-display-none gl-md-display-block">
            <img :src="promoImagePath" :alt="promoImageAlt" class="svg gl-w-full" />
          </div>
        </div>
      </gl-accordion-item>
    </gl-accordion>
  </div>
</template>
