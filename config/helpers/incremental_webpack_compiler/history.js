/* eslint-disable max-classes-per-file, no-underscore-dangle */

const fs = require('fs');
const log = require('./log');

/**
 * The History class is responsible for tracking which entry points have been
 * requested, and persisting/loading the history to/from disk.
 */
class History {
  constructor(historyFilePath) {
    this._historyFilePath = historyFilePath;
    this._history = this._loadHistoryFile();
  }

  onRequestEntryPoint(entryPoint) {
    const wasVisitedRecently = this.isRecentlyVisited(entryPoint);

    if (!this._history[entryPoint]) {
      this._history[entryPoint] = { lastVisit: null, count: 0 };
    }

    this._history[entryPoint].lastVisit = Date.now();
    this._history[entryPoint].count += 1;

    this._writeHistoryFile();

    return wasVisitedRecently;
  }

  // eslint-disable-next-line class-methods-use-this
  isRecentlyVisited() {
    return true;
  }

  // eslint-disable-next-line class-methods-use-this
  get size() {
    return 0;
  }

  // Private methods

  _writeHistoryFile() {
    try {
      fs.writeFileSync(this._historyFilePath, JSON.stringify(this._history), 'utf8');
    } catch (e) {
      log('Warning – Could not write to history', e.message);
    }
  }

  _loadHistoryFile() {
    let history = {};

    try {
      history = JSON.parse(fs.readFileSync(this._historyFilePath, 'utf8'));
      const historySize = Object.keys(history).length;
      log(`Successfully loaded history containing ${historySize} entry points`);
    } catch (error) {
      log(`Could not load history: ${error}`);
    }

    return history;
  }
}

const MS_PER_DAY = 1000 * 60 * 60 * 24;

/**
 * The HistoryWithTTL class adds LRU-like behaviour onto the base History
 * behaviour. Entry points visited within the last `ttl` days are considered
 * "recent", and therefore should be eagerly compiled.
 */
class HistoryWithTTL extends History {
  constructor(historyFilePath, ttl) {
    super(historyFilePath);
    this._ttl = ttl;
    this._calculateRecentEntryPoints();
  }

  onRequestEntryPoint(entryPoint) {
    const wasVisitedRecently = super.onRequestEntryPoint(entryPoint);

    this._calculateRecentEntryPoints();

    return wasVisitedRecently;
  }

  isRecentlyVisited(entryPoint) {
    return this._recentEntryPoints.has(entryPoint);
  }

  get size() {
    return this._recentEntryPoints.size;
  }

  // Private methods

  _calculateRecentEntryPoints() {
    const oldestVisitAllowed = Date.now() - MS_PER_DAY * this._ttl;

    const recentEntryPoints = Object.entries(this._history).reduce(
      (acc, [entryPoint, { lastVisit }]) => {
        if (lastVisit > oldestVisitAllowed) {
          acc.push(entryPoint);
        }

        return acc;
      },
      [],
    );

    this._recentEntryPoints = new Set([
      // Login page
      'pages.sessions.new',
      // Explore page
      'pages.root',
      ...recentEntryPoints,
    ]);
  }
}

module.exports = {
  History,
  HistoryWithTTL,
};
