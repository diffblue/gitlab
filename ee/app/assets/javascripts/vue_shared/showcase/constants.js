import { s__ } from '~/locale';

export const SHOWCASE_CARDS = {
  sast: {
    title: s__('ShowcaseSecurity|Enable Static Application Security Testing (SAST)'),
    description: s__(
      'ShowcaseSecurity|Scan your source code using GitLab CI/CD and uncover vulnerabilities before deploying.',
    ),
    primaryAction: s__('ShowcaseSecurity|Enable SAST'),
  },
  secret_detection: {
    title: s__('ShowcaseSecurity|Enable Secret Detection'),
    description: s__(
      'ShowcaseSecurity|Scan your code to detect unintentionally committed secrets, like keys, passwords, and API tokens.',
    ),
    primaryAction: s__('ShowcaseSecurity|Enable Secret Detection'),
  },
  vulnerability_management: {
    title: s__('ShowcaseSecurity|Vulnerability management'),
    description: s__(
      'ShowcaseSecurity|Access a dedicated area for vulnerability management. This includes a security dashboard, vulnerability report, and settings.',
    ),
    primaryAction: s__('ShowcaseSecurity|Start a free trial'),
    secondaryAction: s__('ShowcaseSecurity|Upgrade now'),
  },
  dependency_scanning: {
    title: s__('ShowcaseSecurity|Dependency scanning'),
    description: s__(
      'ShowcaseSecurity|Find out if your external libraries are safe. Run dependency scanning jobs that check for known vulnerabilities in your external libraries.',
    ),
    primaryAction: s__('ShowcaseSecurity|Start a free trial'),
    secondaryAction: s__('ShowcaseSecurity|Upgrade now'),
  },
  dast: {
    title: s__('ShowcaseSecurity|Dynamic Application Security Testing (DAST)'),
    description: s__(
      'ShowcaseSecurity|Dynamically examine your application for vulnerabilities in deployed environments.',
    ),
    primaryAction: s__('ShowcaseSecurity|Start a free trial'),
    secondaryAction: s__('ShowcaseSecurity|Upgrade now'),
  },
  container_scanning: {
    title: s__('ShowcaseSecurity|Container scanning'),
    description: s__(
      'ShowcaseSecurity|Audit your Docker-based app. Scan for known vulnerabilities in the Docker images where your code is shipped.',
    ),
    primaryAction: s__('ShowcaseSecurity|Start a free trial'),
    secondaryAction: s__('ShowcaseSecurity|Upgrade now'),
  },
};

export const SHOWCASE_SECTIONS = {
  identify: {
    title: s__('ShowcaseSecurity|Identify vulnerabilities in your code now'),
    description: s__(
      'ShowcaseSecurity|Use GitLab CI/CD to analyze your source code for known vulnerabilities. Compare the found vulnerabilities between your source and target branches.',
    ),
  },
  takeNextLevel: {
    title: s__('ShowcaseSecurity|Take your security to the next level'),
    description: s__(
      'ShowcaseSecurity|Start a free 30-day Ultimate trial or upgrade your instance to access organization-wide security and compliance features. See the other features of the Ultimate plan.',
    ),
  },
};
