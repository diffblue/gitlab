<script>
import { GlAccordion, GlAccordionItem, GlIcon, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';

const i18n = {
  synchronizationFailed: s__(`Geo|Synchronization failed - %{error}`),
  verificationFailed: s__(`Geo|Verification failed - %{error}`),
  retryCount: s__('Geo|Retry count'),
  showMore: s__('Geo|Show more'),
};

export default {
  name: 'GeoProjectCardErrors',
  components: {
    GlAccordion,
    GlAccordionItem,
    GlIcon,
    GlSprintf,
  },
  i18n,
  props: {
    synchronizationFailure: {
      type: String,
      required: false,
      default: null,
    },
    verificationFailure: {
      type: String,
      required: false,
      default: null,
    },
    retryCount: {
      type: Number,
      required: true,
    },
  },
};
</script>

<template>
  <div class="project-card-errors">
    <div class="card-header gl-bg-transparent! gl-border-bottom-0! border-top">
      <gl-accordion :header-level="3">
        <gl-accordion-item :title="$options.i18n.showMore">
          <div class="card-body">
            <div class="container gl-p-0">
              <div class="row">
                <div class="col-sm-8">
                  <ul class="unstyled-list list-items-py-2">
                    <li v-if="synchronizationFailure" class="gl-display-flex! gl-text-red-500">
                      <gl-icon name="warning" size="16" />
                      <span class="gl-ml-2">
                        <gl-sprintf :message="$options.i18n.synchronizationFailed">
                          <template #error>
                            {{ synchronizationFailure }}
                          </template>
                        </gl-sprintf>
                      </span>
                    </li>
                    <li v-if="verificationFailure" class="gl-display-flex! gl-text-red-500">
                      <gl-icon name="warning" size="16" />
                      <span class="gl-ml-2">
                        <gl-sprintf :message="$options.i18n.verificationFailed">
                          <template #error>
                            {{ verificationFailure }}
                          </template>
                        </gl-sprintf>
                      </span>
                    </li>
                  </ul>
                </div>
                <div class="col-sm-4">
                  <div class="project-status-title text-muted">
                    {{ $options.i18n.retryCount }}
                  </div>
                  <div class="project-status-content">
                    {{ retryCount }}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </gl-accordion-item>
      </gl-accordion>
    </div>
  </div>
</template>
