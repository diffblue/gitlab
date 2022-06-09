import {
  dateInWords,
  totalDaysInMonth,
  dayInQuarter,
  totalDaysInQuarter,
} from '~/lib/utils/datetime_utility';
import { s__, sprintf } from '~/locale';

import { PRESET_TYPES, DAYS_IN_WEEK } from '../constants';

export default {
  computed: {
    roadmapItem() {
      return this.epic ? this.epic : this.milestone;
    },
    startDateValues() {
      const { startDate } = this.roadmapItem;

      return {
        day: startDate.getDay(),
        date: startDate.getDate(),
        month: startDate.getMonth(),
        year: startDate.getFullYear(),
        time: startDate.getTime(),
      };
    },
    endDateValues() {
      const { endDate } = this.roadmapItem;

      return {
        day: endDate.getDay(),
        date: endDate.getDate(),
        month: endDate.getMonth(),
        year: endDate.getFullYear(),
        time: endDate.getTime(),
      };
    },
    presetTypeQuarters() {
      return this.presetType === PRESET_TYPES.QUARTERS;
    },
    presetTypeMonths() {
      return this.presetType === PRESET_TYPES.MONTHS;
    },
    presetTypeWeeks() {
      return this.presetType === PRESET_TYPES.WEEKS;
    },
    hasToday() {
      return this.isTimeframeForToday(this.timeframeItem);
    },
    hasStartDate() {
      if (this.presetTypeQuarters) {
        return this.hasStartDateForQuarter(this.timeframeItem);
      } else if (this.presetTypeMonths) {
        return this.hasStartDateForMonth(this.timeframeItem);
      } else if (this.presetTypeWeeks) {
        return this.hasStartDateForWeek(this.timeframeItem);
      }
      return false;
    },
    todaysIndex() {
      return this.timeframe.findIndex((item) => this.isTimeframeForToday(item));
    },
    roadmapItemIndex() {
      return this.timeframe.findIndex((item) => {
        if (this.presetTypeQuarters) {
          return this.hasStartDateForQuarter(item);
        } else if (this.presetTypeMonths) {
          return this.hasStartDateForMonth(item);
        } else if (this.presetTypeWeeks) {
          return this.hasStartDateForWeek(item);
        }
        return false;
      });
    },
  },
  methods: {
    isTimeframeForToday(timeframeItem) {
      if (this.presetTypeQuarters) {
        return (
          this.currentDate >= timeframeItem.range[0] && this.currentDate <= timeframeItem.range[2]
        );
      } else if (this.presetTypeMonths) {
        return (
          this.currentDate.getMonth() === timeframeItem.getMonth() &&
          this.currentDate.getFullYear() === timeframeItem.getFullYear()
        );
      }
      const itemTime = new Date(timeframeItem.getTime());
      const headerSubItems = new Array(7)
        .fill()
        .map(
          (_, i) => new Date(itemTime.getFullYear(), itemTime.getMonth(), itemTime.getDate() + i),
        );

      return (
        this.currentDate.getTime() >= headerSubItems[0].getTime() &&
        this.currentDate.getTime() <= headerSubItems[headerSubItems.length - 1].getTime()
      );
    },
    getIndicatorStyles() {
      let left;

      // Get total days of current timeframe Item and then
      // get size in % from current date and days in range
      // based on the current presetType
      if (this.presetTypeQuarters) {
        left = Math.floor(
          (dayInQuarter(this.currentDate, this.timeframeItem.range) /
            totalDaysInQuarter(this.timeframeItem.range)) *
            100,
        );
      } else if (this.presetTypeMonths) {
        left = Math.floor(
          (this.currentDate.getDate() / totalDaysInMonth(this.timeframeItem)) * 100,
        );
      } else if (this.presetTypeWeeks) {
        left = Math.floor(((this.currentDate.getDay() + 1) / DAYS_IN_WEEK) * 100 - DAYS_IN_WEEK);
      }

      return {
        left: `${left}%`,
      };
    },
    timeframeString(roadmapItem) {
      if (roadmapItem.startDateUndefined && roadmapItem.endDateUndefined) {
        return sprintf(s__('GroupRoadmap|No start and end date'));
      } else if (roadmapItem.startDateUndefined) {
        return sprintf(s__('GroupRoadmap|No start date – %{dateWord}'), {
          dateWord: dateInWords(this.endDate, true),
        });
      } else if (roadmapItem.endDateUndefined) {
        return sprintf(s__('GroupRoadmap|%{dateWord} – No end date'), {
          dateWord: dateInWords(this.startDate, true),
        });
      }

      // In case both start and end date fall in same year
      // We should hide year from start date
      const startDateInWords = dateInWords(
        this.startDate,
        true,
        this.startDate.getFullYear() === this.endDate.getFullYear(),
      );

      const endDateInWords = dateInWords(this.endDate, true);
      return sprintf(s__('GroupRoadmap|%{startDateInWords} – %{endDateInWords}'), {
        startDateInWords,
        endDateInWords,
      });
    },
    timelineBarStyles(roadmapItem) {
      let barStyles = {};

      if (this.presetTypeQuarters) {
        // CSS properties are a false positive: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/24
        // eslint-disable-next-line @gitlab/require-i18n-strings
        barStyles = `width: ${this.getTimelineBarWidthForQuarters(
          roadmapItem,
        )}px; ${this.getTimelineBarStartOffsetForQuarters(roadmapItem)}`;
      } else if (this.presetTypeMonths) {
        // eslint-disable-next-line @gitlab/require-i18n-strings
        barStyles = `width: ${this.getTimelineBarWidthForMonths()}px; ${this.getTimelineBarStartOffsetForMonths(
          roadmapItem,
        )}`;
      } else if (this.presetTypeWeeks) {
        // eslint-disable-next-line @gitlab/require-i18n-strings
        barStyles = `width: ${this.getTimelineBarWidthForWeeks()}px; ${this.getTimelineBarStartOffsetForWeeks(
          roadmapItem,
        )}`;
      }

      if (roadmapItem.color) {
        // eslint-disable-next-line @gitlab/require-i18n-strings
        barStyles += `; --epic-color: ${roadmapItem.color}`;
        // eslint-disable-next-line @gitlab/require-i18n-strings
        barStyles += `; --epic-text-color: ${roadmapItem.textColor}`;
      }

      return barStyles;
    },
  },
};
