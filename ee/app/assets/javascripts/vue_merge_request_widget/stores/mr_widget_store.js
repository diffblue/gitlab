import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import CEMergeRequestStore from '~/vue_merge_request_widget/stores/mr_widget_store';
import { mapApprovalsResponse, mapApprovalRulesResponse } from '../mappers';

export default class MergeRequestStore extends CEMergeRequestStore {
  constructor(data) {
    super(data);

    this.sastHelp = data.sast_help_path;
    this.containerScanningHelp = data.container_scanning_help_path;
    this.dastHelp = data.dast_help_path;
    this.apiFuzzingHelp = data.api_fuzzing_help_path;
    this.coverageFuzzingHelp = data.coverage_fuzzing_help_path;
    this.secretDetectionHelp = data.secret_detection_help_path;
    this.dependencyScanningHelp = data.dependency_scanning_help_path;
    this.canReadVulnerabilities = data.can_read_vulnerabilities;
    this.vulnerabilityFeedbackPath = data.vulnerability_feedback_path;
    this.canReadVulnerabilityFeedback = data.can_read_vulnerability_feedback;
    this.securityReportsPipelineId = data.pipeline_id;
    this.securityReportsPipelineIid = data.pipeline_iid;
    this.createVulnerabilityFeedbackIssuePath = data.create_vulnerability_feedback_issue_path;
    this.createVulnerabilityFeedbackMergeRequestPath =
      data.create_vulnerability_feedback_merge_request_path;
    this.createVulnerabilityFeedbackDismissalPath =
      data.create_vulnerability_feedback_dismissal_path;
    this.visualReviewAppAvailable = Boolean(data.visual_review_app_available);
    this.appUrl = gon && gon.gitlab_url;
    this.licenseScanning = data.license_scanning;

    this.initBrowserPerformanceReport(data);
    this.initLoadPerformanceReport(data);
    this.initLicenseComplianceReport(data);

    this.metricsReportsPath = data.metrics_reports_path;

    this.enabledReports = convertObjectPropsToCamelCase(data.enabled_reports);

    this.blockingMergeRequests = data.blocking_merge_requests;

    this.apiApprovalSettingsPath = data.api_approval_settings_path;
  }

  setData(data, isRebased) {
    this.initGeo(data);

    this.mergePipelinesEnabled = Boolean(data.merge_pipelines_enabled);
    this.mergeTrainsCount = data.merge_trains_count || 0;
    this.mergeTrainIndex = data.merge_train_index;
    this.policyViolation = data.policy_violation;
    this.jiraAssociation = data.jira_associations || {};

    super.setData(data, isRebased);
  }

  setPaths(data) {
    // Paths are set on the first load of the page and not auto-refreshed
    super.setPaths(data);

    this.discoverProjectSecurityPath = data.discover_project_security_path;
    this.apiStatusChecksPath = data.api_status_checks_path;

    // Security scan diff paths
    this.containerScanningComparisonPath = data.container_scanning_comparison_path;
    this.coverageFuzzingComparisonPath = data.coverage_fuzzing_comparison_path;
    this.apiFuzzingComparisonPath = data.api_fuzzing_comparison_path;
    this.dastComparisonPath = data.dast_comparison_path;
    this.dependencyScanningComparisonPath = data.dependency_scanning_comparison_path;
  }

  initGeo(data) {
    this.isGeoSecondaryNode = this.isGeoSecondaryNode || data.is_geo_secondary_node;
    this.geoSecondaryHelpPath = this.geoSecondaryHelpPath || data.geo_secondary_help_path;
  }

  initApprovals() {
    super.initApprovals();

    this.approvalRules = this.approvalRules || [];
  }

  setApprovals(data) {
    super.setApprovals(data);

    this.approvals = mapApprovalsResponse(data);
    this.approvalsLeft = Boolean(data.approvals_left);
    this.preventMerge = !this.isApproved;

    this.setState();
  }

  setApprovalRules(data) {
    this.approvalRules = mapApprovalRulesResponse(data.rules, this.approvals);
  }

  get hasMergeChecksFailed() {
    if (this.hasApprovalsAvailable && this.approvals && this.approvalsLeft) return !this.isApproved;

    if (
      (this.blockingMergeRequests?.visible_merge_requests?.merged?.length || 0) !==
      (this.blockingMergeRequests?.total_count || 0)
    )
      return true;

    return super.hasMergeChecksFailed;
  }

  initBrowserPerformanceReport(data) {
    this.browserPerformance = data.browser_performance;
    this.browserPerformanceMetrics = {
      improved: [],
      degraded: [],
      same: [],
    };
  }

  initLoadPerformanceReport(data) {
    this.loadPerformance = data.load_performance;
    this.loadPerformanceMetrics = {
      improved: [],
      degraded: [],
      same: [],
    };
  }

  initLicenseComplianceReport({
    license_scanning_comparison_path,
    license_scanning_comparison_collapsed_path,
    api_approvals_path,
    license_scanning,
  }) {
    this.licenseCompliance = {
      license_scanning_comparison_path,
      license_scanning_comparison_collapsed_path,
      api_approvals_path,
      license_scanning,
    };
  }

  compareBrowserPerformanceMetrics(headMetrics, baseMetrics) {
    const headMetricsIndexed = MergeRequestStore.normalizeBrowserPerformanceMetrics(headMetrics);
    const baseMetricsIndexed = MergeRequestStore.normalizeBrowserPerformanceMetrics(baseMetrics);
    const improved = [];
    const degraded = [];
    const same = [];

    Object.keys(headMetricsIndexed).forEach((subject) => {
      const subjectMetrics = headMetricsIndexed[subject];
      Object.keys(subjectMetrics).forEach((metric) => {
        const headMetricData = subjectMetrics[metric];

        if (baseMetricsIndexed[subject] && baseMetricsIndexed[subject][metric]) {
          const baseMetricData = baseMetricsIndexed[subject][metric];
          const metricData = {
            name: metric,
            path: subject,
            score: headMetricData.value,
            delta: headMetricData.value - baseMetricData.value,
          };

          if (metricData.delta !== 0) {
            const isImproved =
              headMetricData.desiredSize === 'smaller'
                ? metricData.delta < 0
                : metricData.delta > 0;

            if (isImproved) {
              improved.push(metricData);
            } else {
              degraded.push(metricData);
            }
          } else {
            same.push(metricData);
          }
        }
      });
    });

    this.browserPerformanceMetrics = { improved, degraded, same };
  }

  // normalize browser performance metrics by indexing on performance subject and metric name
  static normalizeBrowserPerformanceMetrics(browserPerformanceData) {
    const indexedSubjects = {};
    browserPerformanceData.forEach(({ subject, metrics }) => {
      const indexedMetrics = {};
      metrics.forEach(({ name, ...data }) => {
        indexedMetrics[name] = data;
      });
      indexedSubjects[subject] = indexedMetrics;
    });

    return indexedSubjects;
  }

  compareLoadPerformanceMetrics(headMetrics, baseMetrics) {
    const headMetricsIndexed = MergeRequestStore.normalizeLoadPerformanceMetrics(headMetrics);
    const baseMetricsIndexed = MergeRequestStore.normalizeLoadPerformanceMetrics(baseMetrics);
    const improved = [];
    const degraded = [];
    const same = [];

    Object.keys(headMetricsIndexed).forEach((metric) => {
      const headMetricData = headMetricsIndexed[metric];
      if (metric in baseMetricsIndexed) {
        const baseMetricData = baseMetricsIndexed[metric];
        const metricData = {
          name: metric,
          score: headMetricData,
          delta: parseFloat((parseFloat(headMetricData) - parseFloat(baseMetricData)).toFixed(2)),
        };

        if (metricData.delta !== 0.0) {
          const isImproved = [s__('ciReport|RPS'), s__('ciReport|Checks')].includes(metric)
            ? metricData.delta > 0
            : metricData.delta < 0;

          if (isImproved) {
            improved.push(metricData);
          } else {
            degraded.push(metricData);
          }
        } else {
          same.push(metricData);
        }
      }
    });

    this.loadPerformanceMetrics = { improved, degraded, same };
  }

  // normalize load performance metrics for comsumption
  static normalizeLoadPerformanceMetrics(loadPerformanceData) {
    if (!('metrics' in loadPerformanceData)) return {};

    const { metrics } = loadPerformanceData;
    const indexedMetrics = {};

    Object.keys(loadPerformanceData.metrics).forEach((metric) => {
      switch (metric) {
        case 'http_reqs':
          indexedMetrics[s__('ciReport|RPS')] = metrics.http_reqs.rate;
          break;
        case 'http_req_waiting':
          indexedMetrics[s__('ciReport|TTFB P90')] = metrics.http_req_waiting['p(90)'];
          indexedMetrics[s__('ciReport|TTFB P95')] = metrics.http_req_waiting['p(95)'];
          break;
        case 'checks':
          indexedMetrics[s__('ciReport|Checks')] = `${(
            (metrics.checks.passes / (metrics.checks.passes + metrics.checks.fails)) *
            100.0
          ).toFixed(2)}%`;
          break;
        default:
          break;
      }
    });

    return indexedMetrics;
  }
}
