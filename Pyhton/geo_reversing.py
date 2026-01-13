import os
from dotenv import load_dotenv
import pandas as pd
import sqlalchemy as sa
from sqlalchemy import create_engine
from geopy.geocoders import Nominatim
import time

# Load environment variables from .env file
load_dotenv()

# 1. Connect and Load data into a Pandas DataFrame
connection_url = sa.engine.URL.create(
    "mssql+pyodbc",
    host=os.getenv('HOST'),
    database=os.getenv('DATABASE_URL'),
    query={
        "driver": 'ODBC Driver 17 for SQL Server',
        "trusted_connection": "yes"
    }
)

engine = create_engine(connection_url)

query = """
    SELECT TOP 10
        id, lat, lng
    FROM airbnb.addresses
"""

df = pd.read_sql(query, engine)

# 2. Initialize Geocoder
geolocator = Nominatim(user_agent="excel_exporter")


def get_geo_info(row):

    if not pd.isna(row['lat']) or not pd.isna(row['lng']):

        try:
            print(f"Fetching data for ID: {row['id']}")
            location = geolocator.reverse(
                (row['lat'], row['lng']), timeout=10, language='en')

            if location:
                address_details = location.raw["address"]

                suburb = (address_details.get("suburb")
                          or address_details.get("neighbourhood")
                          or address_details.get("municipality", None)
                          )

                street = address_details.get(
                    "road") or location.raw.get("name", None)
                postcode = address_details.get("postcode", None)
                province = address_details.get("province")
                city = address_details.get("state")
                address_ = f'{suburb}, {province}, {city}, Saudi Arabia'

                # Wait 1 second to comply with usage policy
                time.sleep(1)

                return province, suburb, street, postcode, address_, city

        except Exception as e:
            print(f'Error on ID {row['id']}: {e}')

    return "", "", "", "", "", ""


# 3. Apply the function to the DataFrame
# This updates the Python table, NOT the SQL database
df[['province', 'suburb', 'street', 'postcode', 'address_', 'city']] = df.apply(
    lambda x: pd.Series(get_geo_info(x)), axis=1
)

# print(df[['province', 'suburb', 'street', 'postcode', 'address_', 'city']])
# 4. Export to Excel
df.to_excel("Addresses.xlsx", index=False, sheet_name='addresses')
print("File saved successfully!")
