export const formatStat = (stat, formatter) => {
  if (stat === null || typeof stat === 'undefined' || Number.isNaN(stat)) return '-';
  return formatter(stat);
};
