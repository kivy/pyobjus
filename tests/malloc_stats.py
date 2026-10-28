import ctypes


class _MallocStats(ctypes.Structure):
    _fields_ = [("blocks_in_use", ctypes.c_uint),
                ("size_in_use", ctypes.c_size_t),
                ("max_size_in_use", ctypes.c_size_t),
                ("size_allocated", ctypes.c_size_t)]


def malloc_bytes_in_use():
    """Bytes currently allocated by malloc across all zones (macOS only)."""
    stats = _MallocStats()
    ctypes.CDLL(None).malloc_zone_statistics(None, ctypes.byref(stats))
    return stats.size_in_use
