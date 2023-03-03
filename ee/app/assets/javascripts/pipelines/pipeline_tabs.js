import Vue from 'vue';
import VueRouter from 'vue-router';
import { merge } from 'lodash';
import { createAppOptions as createAppOptionsCE } from '~/pipelines/pipeline_tabs';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { getPipelineReportOptions } from 'ee/security_dashboard/utils/pipeline_report_options';
import { createAlert } from '~/alert';
import { __ } from '~/locale';

Vue.use(VueRouter);

export const createAppOptions = (selector, apolloProvider, router) => {
  const el = document.querySelector(selector);

  if (!el) return null;

  const appOptionsCE = createAppOptionsCE(selector, apolloProvider, router);

  const { dataset } = el;

  let vulnerabilityReportData = {};
  let vulnerabilityReportProvides = {};
  try {
    vulnerabilityReportData = convertObjectPropsToCamelCase(
      JSON.parse(dataset.vulnerabilityReportData),
    );
    vulnerabilityReportProvides = getPipelineReportOptions(vulnerabilityReportData);
  } catch (error) {
    createAlert({
      message: __("Unable to parse the vulnerability report's options."),
      error,
    });
  }

  return merge({}, appOptionsCE, {
    provide: vulnerabilityReportProvides,
  });
};
