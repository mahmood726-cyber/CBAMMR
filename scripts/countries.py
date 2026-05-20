"""Canonical list of African countries used across the atlas.

Codes follow ISO 3166-1. WHO and World Bank both accept alpha-3 for most
endpoints; ClinicalTrials.gov uses country names.
"""

AFRICAN_COUNTRIES = [
    # (alpha-2, alpha-3, name, who_region)
    ("DZ", "DZA", "Algeria", "AFR"),
    ("AO", "AGO", "Angola", "AFR"),
    ("BJ", "BEN", "Benin", "AFR"),
    ("BW", "BWA", "Botswana", "AFR"),
    ("BF", "BFA", "Burkina Faso", "AFR"),
    ("BI", "BDI", "Burundi", "AFR"),
    ("CV", "CPV", "Cabo Verde", "AFR"),
    ("CM", "CMR", "Cameroon", "AFR"),
    ("CF", "CAF", "Central African Republic", "AFR"),
    ("TD", "TCD", "Chad", "AFR"),
    ("KM", "COM", "Comoros", "AFR"),
    ("CG", "COG", "Congo", "AFR"),
    ("CD", "COD", "Democratic Republic of the Congo", "AFR"),
    ("CI", "CIV", "Cote d'Ivoire", "AFR"),
    ("DJ", "DJI", "Djibouti", "EMR"),
    ("EG", "EGY", "Egypt", "EMR"),
    ("GQ", "GNQ", "Equatorial Guinea", "AFR"),
    ("ER", "ERI", "Eritrea", "AFR"),
    ("SZ", "SWZ", "Eswatini", "AFR"),
    ("ET", "ETH", "Ethiopia", "AFR"),
    ("GA", "GAB", "Gabon", "AFR"),
    ("GM", "GMB", "Gambia", "AFR"),
    ("GH", "GHA", "Ghana", "AFR"),
    ("GN", "GIN", "Guinea", "AFR"),
    ("GW", "GNB", "Guinea-Bissau", "AFR"),
    ("KE", "KEN", "Kenya", "AFR"),
    ("LS", "LSO", "Lesotho", "AFR"),
    ("LR", "LBR", "Liberia", "AFR"),
    ("LY", "LBY", "Libya", "EMR"),
    ("MG", "MDG", "Madagascar", "AFR"),
    ("MW", "MWI", "Malawi", "AFR"),
    ("ML", "MLI", "Mali", "AFR"),
    ("MR", "MRT", "Mauritania", "AFR"),
    ("MU", "MUS", "Mauritius", "AFR"),
    ("MA", "MAR", "Morocco", "EMR"),
    ("MZ", "MOZ", "Mozambique", "AFR"),
    ("NA", "NAM", "Namibia", "AFR"),
    ("NE", "NER", "Niger", "AFR"),
    ("NG", "NGA", "Nigeria", "AFR"),
    ("RW", "RWA", "Rwanda", "AFR"),
    ("ST", "STP", "Sao Tome and Principe", "AFR"),
    ("SN", "SEN", "Senegal", "AFR"),
    ("SC", "SYC", "Seychelles", "AFR"),
    ("SL", "SLE", "Sierra Leone", "AFR"),
    ("SO", "SOM", "Somalia", "EMR"),
    ("ZA", "ZAF", "South Africa", "AFR"),
    ("SS", "SSD", "South Sudan", "AFR"),
    ("SD", "SDN", "Sudan", "EMR"),
    ("TZ", "TZA", "United Republic of Tanzania", "AFR"),
    ("TG", "TGO", "Togo", "AFR"),
    ("TN", "TUN", "Tunisia", "EMR"),
    ("UG", "UGA", "Uganda", "AFR"),
    ("ZM", "ZMB", "Zambia", "AFR"),
    ("ZW", "ZWE", "Zimbabwe", "AFR"),
    ("EH", "ESH", "Western Sahara", "AFR"),
]


def iter_countries():
    for a2, a3, name, region in AFRICAN_COUNTRIES:
        yield {"iso2": a2, "iso3": a3, "name": name, "who_region": region}


def names():
    return [c["name"] for c in iter_countries()]


def iso3_codes():
    return [c["iso3"] for c in iter_countries()]
