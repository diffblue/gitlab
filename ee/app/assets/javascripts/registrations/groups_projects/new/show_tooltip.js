import { initTooltips, add } from '~/tooltips';

export default function showTooltip(tooltipSelector, config = {}) {
  const tooltip = document.querySelector(tooltipSelector);

  if (!tooltip) return null;

  initTooltips({ selector: tooltipSelector });
  return add([tooltip], Object.assign(config, { show: true }));
}
