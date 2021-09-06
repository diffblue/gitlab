import { initTooltips, add } from '~/tooltips';

export default function showTooltip(tooltipSelector) {
  const tooltip = document.querySelector(tooltipSelector);

  if (!tooltip) return null;

  initTooltips({ selector: tooltipSelector });
  return add([tooltip], { show: true });
}
