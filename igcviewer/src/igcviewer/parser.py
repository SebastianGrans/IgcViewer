import math
import re
from pathlib import Path

from .models import FlightData, FlightPoint

_B_RECORD = re.compile(
    r"^B(\d{6})(\d{7})([NS])(\d{8})([EW])([AV])(\d{5})(\d{5})",
    re.MULTILINE,
)


def _parse_coordinate(raw: str, hemisphere: str) -> float:
    if hemisphere in ("N", "S"):
        degrees = int(raw[:2])
        minutes = int(raw[2:4])
        milli_minutes = int(raw[4:7])
    else:
        degrees = int(raw[:3])
        minutes = int(raw[3:5])
        milli_minutes = int(raw[5:8])
    decimal = degrees + minutes / 60.0 + milli_minutes / 60000.0
    return -decimal if hemisphere in ("S", "W") else decimal


def _haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371000.0
    d_lat = math.radians(lat2 - lat1)
    d_lon = math.radians(lon2 - lon1)
    a = math.sin(d_lat / 2) ** 2 + (
        math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(d_lon / 2) ** 2
    )
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def _median3(a: float, b: float, c: float) -> float:
    return sorted([a, b, c])[1]


def parse_igc(path: str) -> FlightData:
    try:
        content = Path(path).read_text(errors="replace")
    except OSError:
        return FlightData()

    data = FlightData()

    for m in _B_RECORD.finditer(content):
        time_str, lat_raw, lat_hem, lon_raw, lon_hem, status, baro_raw, gps_raw = m.groups()
        if status == "V":
            continue
        lat = _parse_coordinate(lat_raw, lat_hem)
        lon = _parse_coordinate(lon_raw, lon_hem)
        alt_gps = int(gps_raw)
        alt_baro = int(baro_raw)
        alt = alt_gps if alt_gps > -500 else alt_baro
        seconds = int(time_str[:2]) * 3600 + int(time_str[2:4]) * 60 + int(time_str[4:6])
        data.points.append(FlightPoint(lat=lat, lon=lon, alt=alt, time=time_str, seconds=seconds))

    if len(data.points) < 2:
        return data

    data.distances.append(0.0)
    cum_dist = 0.0
    climbs: list[float] = []
    speeds: list[float] = []
    stats = data.stats
    stats.max_alt = data.points[0].alt
    stats.min_alt = data.points[0].alt

    for i in range(1, len(data.points)):
        p1, p2 = data.points[i - 1], data.points[i]
        seg = _haversine(p1.lat, p1.lon, p2.lat, p2.lon)
        cum_dist += seg
        data.distances.append(cum_dist / 1000.0)

        dt = max(1, p2.seconds - p1.seconds)
        vz = (p2.alt - p1.alt) / dt
        gs = (seg / dt) * 3.6  # km/h

        if p2.alt > stats.max_alt:
            stats.max_alt = p2.alt
        if p2.alt < stats.min_alt:
            stats.min_alt = p2.alt
        climbs.append(vz)
        speeds.append(gs)

    # 3-point median filter on ground speeds
    smoothed = [
        _median3(
            speeds[i - 1] if i > 0 else speeds[i],
            speeds[i],
            speeds[i + 1] if i + 1 < len(speeds) else speeds[i],
        )
        for i in range(len(speeds))
    ]
    stats.max_speed = max(smoothed)

    # Filter climb rates to remove GPS noise (-10 to +10 m/s)
    valid_climbs = [v for v in climbs if -10 < v < 10]
    if valid_climbs:
        pos = [v for v in valid_climbs if v > 0]
        neg = [v for v in valid_climbs if v <= 0]
        if pos:
            stats.max_climb = max(pos)
        if neg:
            stats.max_sink = min(neg)

        # Thermal detection: consecutive climbs > 0.3 m/s, at least 2 samples
        thermals: list[float] = []
        in_thermal = False
        th_sum = 0.0
        th_cnt = 0
        for v in climbs:
            if v > 0.3:
                if not in_thermal:
                    in_thermal = True
                    th_sum = 0.0
                    th_cnt = 0
                th_sum += v
                th_cnt += 1
            elif in_thermal:
                if th_cnt >= 2:
                    thermals.append(th_sum / th_cnt)
                in_thermal = False
        if thermals:
            stats.avg_thermal_climb = sum(thermals) / len(thermals)

    stats.flight_dist = cum_dist / 1000.0
    stats.gain = max(0, stats.max_alt - stats.min_alt)
    stats.point_count = len(data.points)
    data.valid = True
    return data
