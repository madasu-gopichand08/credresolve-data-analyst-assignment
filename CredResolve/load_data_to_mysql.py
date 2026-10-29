import csv
import re
from pathlib import Path

import mysql.connector

# Project configuration
PROJECT_DIR = Path(__file__).resolve().parent
DATASET_DIR = PROJECT_DIR / "dataset"

DB_CONFIG = {
    "host": "localhost",
    "user": "root",
    "password": input("Enter your MySQL root password: "),
    "database": "credresolve",
}

def safe_table_name(filename):
    """Convert a CSV filename into a safe MySQL table name."""
    name = Path(filename).stem.lower()
    return re.sub(r"[^a-z0-9_]", "_", name)

def main():
    csv_files = sorted(DATASET_DIR.glob("*.csv"))

    if not csv_files:
        print(f"No CSV files found in {DATASET_DIR}")
        return

    connection = mysql.connector.connect(**DB_CONFIG)
    cursor = connection.cursor()

    try:
        for csv_file in csv_files:
            table = safe_table_name(csv_file.name)
            print(f"\nImporting {csv_file.name} -> {table}")

            with csv_file.open("r", encoding="utf-8-sig", newline="") as file:
                reader = csv.reader(file)
                headers = next(reader, None)

                if not headers:
                    print("  Skipped: empty file")
                    continue

                # Clean column names for MySQL compatibility.
                columns = []
                for header in headers:
                    column = re.sub(r"[^a-zA-Z0-9_]", "_", header.strip())
                    if not column or column[0].isdigit():
                        column = f"col_{column}"
                    columns.append(column.lower())

                if len(set(columns)) != len(columns):
                    raise ValueError(
                        f"Duplicate column names after cleaning in {csv_file.name}: {columns}"
                    )

                column_sql = ", ".join(f"`{col}` TEXT" for col in columns)

                cursor.execute(
                    f"CREATE TABLE IF NOT EXISTS `{table}` ({column_sql})"
                )

                # Load into a fresh table so reruns do not duplicate rows.
                cursor.execute(f"TRUNCATE TABLE `{table}`")

                placeholders = ", ".join(["%s"] * len(columns))
                insert_sql = (
                    f"INSERT INTO `{table}` "
                    f"({', '.join(f'`{col}`' for col in columns)}) "
                    f"VALUES ({placeholders})"
                )

                batch = []
                imported = 0

                for row in reader:
                    # Pad or trim malformed rows to match the header width.
                    row = (row + [None] * len(columns))[:len(columns)]
                    batch.append([value if value != "" else None for value in row])

                    if len(batch) >= 1000:
                        cursor.executemany(insert_sql, batch)
                        imported += len(batch)
                        batch.clear()

                if batch:
                    cursor.executemany(insert_sql, batch)
                    imported += len(batch)

                connection.commit()
                print(f"  Imported {imported:,} rows")

        print("\nAll CSV imports completed.")

    finally:
        cursor.close()
        connection.close()

if __name__ == "__main__":
    main()
