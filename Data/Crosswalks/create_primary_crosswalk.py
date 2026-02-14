#!/usr/bin/env python3
"""Create primary ZCTA-County crosswalk (largest area overlap)"""

import csv
from collections import defaultdict

# Read full crosswalk
zcta_counties = defaultdict(list)
with open('zcta_county_full.csv', 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        zcta = row['zcta']
        county_fips = row['county_fips']
        county_name = row['county_name']
        area = int(row['area_land']) if row['area_land'] else 0
        zcta_counties[zcta].append((area, county_fips, county_name))

# Write primary crosswalk (county with largest area)
with open('zcta_county_primary.csv', 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['zcta', 'county_fips', 'county_name'])
    for zcta in sorted(zcta_counties.keys()):
        counties = zcta_counties[zcta]
        # Sort by area descending, pick first
        counties.sort(key=lambda x: x[0], reverse=True)
        area, county_fips, county_name = counties[0]
        writer.writerow([zcta, county_fips, county_name])

print(f"Created primary crosswalk with {len(zcta_counties)} ZCTAs")
