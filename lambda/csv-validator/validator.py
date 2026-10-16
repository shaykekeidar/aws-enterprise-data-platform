
import csv
import json
from datetime import datetime
from pathlib import Path


def validate_value(value, expected_type):
    """Validate a CSV value against its expected data type."""

    if value is None or value.strip() == "":
        return False

    try:
        if expected_type == "integer":
            int(value)

        elif expected_type == "float":
            float(value)

        elif expected_type == "date":
            datetime.strptime(value, "%Y-%m-%d")

        elif expected_type == "string":
            pass

        else:
            raise ValueError(f"Unsupported type: {expected_type}")

        return True

    except ValueError:
        return False


def validate_csv(csv_path, schema_path):
    """Validate CSV column structure and data types."""

    # Load predefined schema
    with open(schema_path, encoding="utf-8") as file:
        schema = json.load(file)["columns"]

    expected_columns = list(schema.keys())
    errors = []

    # Open CSV file
    with open(csv_path, newline="", encoding="utf-8-sig") as file:
        reader = csv.DictReader(file)

        # 1. Validate column names and order
        if reader.fieldnames != expected_columns:
            return False, [
                f"Invalid columns. Expected: {expected_columns}, "
                f"Received: {reader.fieldnames}"
            ]

        # 2. Validate each row
        for row_number, row in enumerate(reader, start=2):

            # Reject rows with extra columns
            if None in row:
                errors.append(
                    f"Row {row_number}: too many columns. "
                    f"Unexpected values: {row[None]}"
                )
                continue

            # Reject rows with missing columns
            missing_columns = [
                column
                for column in expected_columns
                if row[column] is None
            ]

            if missing_columns:
                errors.append(
                    f"Row {row_number}: missing values for "
                    f"columns {missing_columns}"
                )
                continue

            # 3. Validate data types
            for column, expected_type in schema.items():
                value = row[column]

                if not validate_value(value, expected_type):
                    errors.append(
                        f"Row {row_number}: column '{column}' "
                        f"has invalid value '{value}' "
                        f"(expected {expected_type})"
                    )

    return len(errors) == 0, errors


if __name__ == "__main__":
    base_dir = Path(__file__).parent

    valid, errors = validate_csv(
        base_dir / "sample.csv",
        base_dir / "schema.json"
    )

    if valid:
        print("CSV validation PASSED")
    else:
        print("CSV validation FAILED")

        for error in errors:
            print(f"- {error}")