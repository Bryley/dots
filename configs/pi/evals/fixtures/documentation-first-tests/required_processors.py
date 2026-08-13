"""Utilities for determining concurrent processor requirements."""

from __future__ import annotations

import heapq


def required_processors(
    jobs: list[tuple[int, int]], cooldown: int = 0
) -> int:
    """Return the minimum processors needed to run all jobs.

    Each ``(start, end)`` pair occupies one processor during the half-open
    interval ``[start, end)``. After a job ends, its processor remains
    unavailable for ``cooldown`` additional time units. Jobs whose start and
    end are equal consume no processor. Raise ``ValueError`` if a job ends
    before it starts, or if ``cooldown`` is negative.
    """
    if cooldown < 0:
        raise ValueError("cooldown must not be negative")

    active_until: list[int] = []
    maximum_active = 0

    for start, end in jobs:
        if end < start:
            raise ValueError("job cannot end before it starts")
        if start == end:
            continue

        while active_until and active_until[0] <= start:
            heapq.heappop(active_until)

        heapq.heappush(active_until, end + cooldown)
        maximum_active = max(maximum_active, len(active_until))

    return maximum_active
