## Gitlab::Insights

The goal of the `Gitlab::Insights::` classes is to:

1. Find the raw data,
1. Reduce them depending on certain conditions,
1. Serialize the reduced data into a payload that can be JSON'ed and used on the
  frontend by the graphing library.

### Architecture diagram

```mermaid
graph TD
subgraph Gitlab::Insights::Loader
    A[Executors::] --> |"dispatches the request to the correct (Issuable) executor"| B;
    B[Finders::] --> |"returns issuables Active Record (AR) relation"| C;
    C[Reducers::] --> |reduces issuables AR relation into a hash of chart data| D
    D[Serializers::] --> |serializes chart data to be consumable by the frontend and the charting library| E
    E(JSON-compatible payload used by the frontend to build the chart)
    end
```

#### Specific example

```mermaid
graph TD
subgraph Gitlab::Insights::IssuableExecutor
    A[Finders::IssuableFinder] --> B;
    B[Reducers::LabelCountPerPeriodReducer] --> C
    C[Serializers::Chartjs::MultiSeriesSerializer] --> D
    D(JSON-compatible payload used by the frontend to build the graph)
    end
```
