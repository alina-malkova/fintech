BEGIN { FS=","; OFS="," }
NR==1 { print "zcta", "county_fips", "county_name"; next }
$1 != prev { print $1, $2, $3; prev=$1 }
