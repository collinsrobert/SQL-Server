ALTER DATABASE F92DEV
SET QUERY_STORE = ON;

ALTER DATABASE F92DEV
SET QUERY_STORE (
    OPERATION_MODE = READ_WRITE, -- Start collecting
    CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), -- Keep 30 days of data
    DATA_FLUSH_INTERVAL_SECONDS = 900, -- Flush to disk every 15 minutes
    INTERVAL_LENGTH_MINUTES = 15, -- Data aggregation period
    MAX_STORAGE_SIZE_MB = 10240, -- Cap storage usage (tune as needed)
    QUERY_CAPTURE_MODE = AUTO, -- Smart capture; skips trivial queries
    SIZE_BASED_CLEANUP_MODE = AUTO, -- Automatically clean when near limit
    MAX_PLANS_PER_QUERY = 200 -- Helps track regressions but not overload
);
