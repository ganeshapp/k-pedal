#!/usr/bin/env python3
"""
One-shot pre-computation: for every cycling path in `assets/data/paths.json`,
calculate
  - per-route-segment polyline distance and elevation profile
  - per-checkpoint-pair distance + elevation profile (preferring along-route
    when both checkpoints sit close to the same route segment, otherwise
    falling back to straight-line)
  - per-path total along-checkpoint distance and concatenated elevation profile

The results are written back into the same JSON, so the Flutter app can render
everything offline with no runtime API calls.

Elevation source: Open-Topo-Data SRTM30m (https://www.opentopodata.org/)
  - free, no API key
  - SRTM 30m global coverage
  - 100 locations / request, ~1 call / second
"""

from __future__ import annotations

import json
import math
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

PATHS_JSON = Path(__file__).resolve().parent.parent / "assets" / "data" / "paths.json"

# Tunables
SEGMENT_SAMPLES = 80
CHECKPOINT_SLICE_SAMPLES = 30
BATCH = 100
REQ_INTERVAL_S = 1.1
ELEVATION_URL = "https://api.opentopodata.org/v1/srtm30m"
PAIR_SNAP_THRESHOLD_KM = 2.5   # max perpendicular distance for a checkpoint to count as "on" a segment


# ─── Geometry helpers ────────────────────────────────────────────────────────

EARTH_R_KM = 6371.0088


def haversine_km(a, b):
    p1 = math.radians(a[0])
    p2 = math.radians(b[0])
    dp = math.radians(b[0] - a[0])
    dl = math.radians(b[1] - a[1])
    h = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * EARTH_R_KM * math.asin(math.sqrt(h))


def cumulative_distances(coords):
    out = [0.0]
    for i in range(1, len(coords)):
        out.append(out[-1] + haversine_km(coords[i - 1], coords[i]))
    return out


def downsample_uniform_by_distance(coords, n):
    if len(coords) <= n:
        return list(coords), cumulative_distances(coords)
    cum = cumulative_distances(coords)
    total = cum[-1]
    if total <= 0:
        return [coords[0]], [0.0]
    targets = [total * i / (n - 1) for i in range(n)]
    picked, picked_cum = [], []
    j = 0
    for t in targets:
        while j + 1 < len(cum) and cum[j + 1] < t:
            j += 1
        if j + 1 < len(cum) and abs(cum[j + 1] - t) < abs(cum[j] - t):
            idx = j + 1
        else:
            idx = j
        picked.append(coords[idx])
        picked_cum.append(cum[idx])
    return picked, picked_cum


def project_point_onto_polyline(pt, coords, cum):
    """Returns (along_km, perpendicular_distance_km) of the closest snap."""
    best_along = 0.0
    best_dist = float("inf")
    for i in range(len(coords) - 1):
        a, b = coords[i], coords[i + 1]
        seg_len = cum[i + 1] - cum[i]
        if seg_len <= 1e-9:
            d = haversine_km(pt, a)
            if d < best_dist:
                best_dist = d
                best_along = cum[i]
            continue
        lat0 = math.radians((a[0] + b[0]) / 2)
        kx = EARTH_R_KM * math.cos(lat0)
        ky = EARTH_R_KM
        ax = math.radians(a[1]) * kx
        ay = math.radians(a[0]) * ky
        bx = math.radians(b[1]) * kx
        by = math.radians(b[0]) * ky
        px = math.radians(pt[1]) * kx
        py = math.radians(pt[0]) * ky
        dx, dy = bx - ax, by - ay
        t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)
        t = max(0.0, min(1.0, t))
        cx = ax + t * dx
        cy = ay + t * dy
        d = math.hypot(px - cx, py - cy)
        if d < best_dist:
            best_dist = d
            best_along = cum[i] + t * seg_len
    return best_along, best_dist


def slice_polyline_by_distance(coords, cum, a_km, b_km):
    if a_km > b_km:
        a_km, b_km = b_km, a_km
    a_km = max(0.0, a_km)
    b_km = min(cum[-1], b_km)
    out = [_interp_point(coords, cum, a_km)]
    for i, c in enumerate(coords):
        if a_km < cum[i] < b_km:
            out.append(c)
    end_pt = _interp_point(coords, cum, b_km)
    if end_pt != out[-1]:
        out.append(end_pt)
    return out


def _interp_point(coords, cum, at_km):
    if at_km <= 0:
        return coords[0]
    if at_km >= cum[-1]:
        return coords[-1]
    for i in range(len(coords) - 1):
        if cum[i] <= at_km <= cum[i + 1]:
            seg = cum[i + 1] - cum[i]
            if seg <= 1e-9:
                return coords[i]
            t = (at_km - cum[i]) / seg
            return (
                coords[i][0] + (coords[i + 1][0] - coords[i][0]) * t,
                coords[i][1] + (coords[i + 1][1] - coords[i][1]) * t,
            )
    return coords[-1]


# ─── Elevation API ───────────────────────────────────────────────────────────

_last_request_time = 0.0


def fetch_elevations(coords):
    """Fetch elevations for a list of (lat, lng). Batches automatically."""
    global _last_request_time
    out = []
    for i in range(0, len(coords), BATCH):
        chunk = coords[i : i + BATCH]
        locations = "|".join(f"{lat:.6f},{lng:.6f}" for lat, lng in chunk)
        url = f"{ELEVATION_URL}?locations={urllib.parse.quote(locations, safe=',|')}"
        for attempt in range(4):
            wait = REQ_INTERVAL_S - (time.time() - _last_request_time)
            if wait > 0:
                time.sleep(wait)
            try:
                with urllib.request.urlopen(url, timeout=30) as r:
                    data = json.loads(r.read().decode())
                _last_request_time = time.time()
                if data.get("status") != "OK":
                    raise RuntimeError(f"API error: {data.get('error') or data}")
                results = data["results"]
                # API returns null for missing tiles — clamp to 0
                out.extend(float(r["elevation"]) if r["elevation"] is not None else 0.0 for r in results)
                break
            except Exception as exc:
                _last_request_time = time.time()
                if attempt == 3:
                    raise
                back = 2 ** attempt
                print(f"    retry in {back}s ({exc})", file=sys.stderr)
                time.sleep(back)
    return out


# ─── Per-path computation ────────────────────────────────────────────────────


def find_best_segment_for_pair(a_pt, b_pt, seg_coords, seg_cum):
    """Return (segment_idx, a_along_km, b_along_km, score) for the segment that
    best fits both checkpoints, or None if no segment fits."""
    best = None
    for si, (coords, cum) in enumerate(zip(seg_coords, seg_cum)):
        if len(coords) < 2:
            continue
        a_along, a_perp = project_point_onto_polyline(a_pt, coords, cum)
        b_along, b_perp = project_point_onto_polyline(b_pt, coords, cum)
        if a_perp > PAIR_SNAP_THRESHOLD_KM or b_perp > PAIR_SNAP_THRESHOLD_KM:
            continue
        score = max(a_perp, b_perp)
        if best is None or score < best[3]:
            best = (si, a_along, b_along, score)
    return best


def process_path(path):
    name = path["name"]
    print(f"\n[{path['id']}] {name}")

    routes = path.get("routes", [])
    seg_coords = []
    seg_cum = []
    for r in routes:
        coords = [(c[0], c[1]) for c in r["coordinates"]]
        seg_coords.append(coords)
        seg_cum.append(cumulative_distances(coords))
        r["distance_km"] = round(seg_cum[-1][-1], 3)
        print(f"  segment '{r['name']}': {len(coords)} pts, {r['distance_km']:.2f} km")

    # ── Build the full list of coordinates we'll need elevations for ──
    # Combine segment downsamples + per-pair slice samples into one big batch.
    elevation_jobs = []  # list of (job_id, coords)

    # Segment elevation profiles
    for si, (r, coords, cum) in enumerate(zip(routes, seg_coords, seg_cum)):
        if len(coords) < 2:
            r["elevations"] = []
            continue
        n = min(SEGMENT_SAMPLES, len(coords))
        sampled, sampled_cum = downsample_uniform_by_distance(coords, n)
        elevation_jobs.append((("segment", si), sampled, sampled_cum))

    # Checkpoint pairs
    checkpoints = path.get("checkpoints", [])
    pair_results = []  # list of dicts to fill in after elevation fetch
    for i in range(len(checkpoints) - 1):
        a_pt = (checkpoints[i]["lat"], checkpoints[i]["lng"])
        b_pt = (checkpoints[i + 1]["lat"], checkpoints[i + 1]["lng"])
        best = find_best_segment_for_pair(a_pt, b_pt, seg_coords, seg_cum)
        if best is not None:
            si, a_along, b_along, _ = best
            slice_pts = slice_polyline_by_distance(
                seg_coords[si], seg_cum[si], a_along, b_along
            )
            slice_cum = cumulative_distances(slice_pts)
            dist_km = slice_cum[-1]
            method = f"along-route ({routes[si]['name']})"
        else:
            dist_km = haversine_km(a_pt, b_pt)
            n = 8
            slice_pts = [
                (
                    a_pt[0] + (b_pt[0] - a_pt[0]) * t / (n - 1),
                    a_pt[1] + (b_pt[1] - a_pt[1]) * t / (n - 1),
                )
                for t in range(n)
            ]
            slice_cum = [dist_km * t / (n - 1) for t in range(n)]
            method = "straight-line"

        n_samples = min(CHECKPOINT_SLICE_SAMPLES, len(slice_pts))
        sampled, sampled_cum = downsample_uniform_by_distance(slice_pts, n_samples)
        pair_id = ("pair", i)
        elevation_jobs.append((pair_id, sampled, sampled_cum))
        pair_results.append(
            {
                "from": checkpoints[i]["id"],
                "to": checkpoints[i + 1]["id"],
                "from_name": checkpoints[i]["name"],
                "to_name": checkpoints[i + 1]["name"],
                "distance_km": round(dist_km, 3),
                "method": method,
                "_pair_index": i,
            }
        )

    # ── One big de-duplicated elevation fetch ──
    all_coords = []
    coord_index = {}  # (lat, lng) -> idx into all_coords
    for _, sampled, _ in elevation_jobs:
        for c in sampled:
            key = (round(c[0], 6), round(c[1], 6))
            if key not in coord_index:
                coord_index[key] = len(all_coords)
                all_coords.append((key[0], key[1]))
    print(f"  fetching {len(all_coords)} unique elevation samples in {math.ceil(len(all_coords) / BATCH)} batches…")
    all_elevs = fetch_elevations(all_coords)

    def lookup_elev(c):
        return all_elevs[coord_index[(round(c[0], 6), round(c[1], 6))]]

    # ── Fill in segment elevations ──
    for (kind, idx), sampled, sampled_cum in elevation_jobs:
        if kind != "segment":
            continue
        elevs = [lookup_elev(c) for c in sampled]
        routes[idx]["elevations"] = [
            {"d": round(d, 3), "e": round(e, 1)} for d, e in zip(sampled_cum, elevs)
        ]
        gain = sum(max(0.0, e2 - e1) for e1, e2 in zip(elevs, elevs[1:]))
        if elevs:
            print(
                f"    {routes[idx]['name'][:35]:35s}  "
                f"min {min(elevs):4.0f}m  max {max(elevs):4.0f}m  gain +{gain:4.0f}m"
            )

    # ── Fill in pair data + assemble overall profile ──
    overall_profile = []
    cumulative_path_km = 0.0
    total_km = 0.0
    pair_data_clean = []
    for (kind, idx), sampled, sampled_cum in elevation_jobs:
        if kind != "pair":
            continue
        pair = pair_results[idx]
        elevs = [lookup_elev(c) for c in sampled]
        slice_profile = [
            {"d": round(d, 3), "e": round(e, 1)} for d, e in zip(sampled_cum, elevs)
        ]
        pair["elevations"] = slice_profile
        pair_clean = {k: v for k, v in pair.items() if not k.startswith("_")}
        pair_data_clean.append(pair_clean)
        for j, p in enumerate(slice_profile):
            if j == 0 and overall_profile:
                continue
            overall_profile.append(
                {"d": round(cumulative_path_km + p["d"], 3), "e": p["e"]}
            )
        cumulative_path_km += pair["distance_km"]
        total_km += pair["distance_km"]
        print(
            f"  {pair['from_name'][:30]:30s} → {pair['to_name'][:30]:30s}  "
            f"{pair['distance_km']:6.2f} km  [{pair['method']}]"
        )

    path["total_distance_km"] = round(total_km, 2)
    path["checkpoint_pairs"] = pair_data_clean
    path["overall_elevation"] = overall_profile

    # Overall gain / loss
    if len(overall_profile) >= 2:
        gain = sum(max(0.0, overall_profile[i + 1]["e"] - overall_profile[i]["e"])
                   for i in range(len(overall_profile) - 1))
        loss = sum(max(0.0, overall_profile[i]["e"] - overall_profile[i + 1]["e"])
                   for i in range(len(overall_profile) - 1))
        path["elevation_gain_m"] = round(gain, 1)
        path["elevation_loss_m"] = round(loss, 1)
    else:
        path["elevation_gain_m"] = 0
        path["elevation_loss_m"] = 0
    print(f"  TOTAL: {total_km:.2f} km  +{path['elevation_gain_m']:.0f}m / -{path['elevation_loss_m']:.0f}m  "
          f"({len(overall_profile)} elev pts)")


def main():
    only = None
    if len(sys.argv) > 1:
        only = set(int(x) for x in sys.argv[1:])
        print(f"Restricting to path id(s): {sorted(only)}")
    raw = PATHS_JSON.read_text()
    data = json.loads(raw)
    for path in data["paths"]:
        if only is not None and path["id"] not in only:
            continue
        process_path(path)
    PATHS_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2))
    print(f"\nWrote {PATHS_JSON}")


if __name__ == "__main__":
    main()
