"""Checks that the pipeline can read the Google Sheet linked to the form.

Prints the first few responses. Writes nothing to the database.
Run from the project root with the virtual environment active:
    python etl/check_google_sheet.py
"""
import os
import sys

import gspread
import pandas as pd

from db import PROJECT_ROOT  # importing db also loads .env


def main():
    key_file = PROJECT_ROOT / os.environ["GOOGLE_SERVICE_ACCOUNT_FILE"]
    sheet_id = os.environ["GOOGLE_SHEET_ID"]

    if not key_file.exists():
        sys.exit(f"Key file not found: {key_file}\nDownload it from Google Cloud and save it there.")
    if sheet_id == "change_me":
        sys.exit("Set GOOGLE_SHEET_ID in .env (the part of the sheet URL between /d/ and /edit).")

    client = gspread.service_account(filename=key_file)
    print(f"Signed in as service account: {client.http_client.auth.service_account_email}")

    try:
        spreadsheet = client.open_by_key(sheet_id)
    except gspread.exceptions.SpreadsheetNotFound:
        sys.exit("Sheet not found. Check GOOGLE_SHEET_ID, and that the sheet is shared "
                 "with the service account email above.")
    except gspread.exceptions.APIError as error:
        sys.exit(f"Google refused the request:\n{error}\n\nIf it mentions 'has not been used' "
                 "or 'disabled', enable the Google Sheets API for your Cloud project.")

    # get_all_values() returns every cell as text, which is what raw wants
    rows = spreadsheet.sheet1.get_all_values()
    if len(rows) < 2:
        sys.exit(f"Opened '{spreadsheet.title}', but it has no responses yet. Submit the form a few times.")

    df = pd.DataFrame(rows[1:], columns=rows[0])
    print(f"Opened '{spreadsheet.title}': {len(df)} responses, {len(df.columns)} columns\n")
    print("Columns:")
    for name in df.columns:
        print(f"  - {name}")
    print("\nFirst 5 responses:")
    print(df.head().to_string(index=False))


if __name__ == "__main__":
    main()
