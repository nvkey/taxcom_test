import csv
import json
import os
import sqlite3
from enum import Enum
from pathlib import Path
from sqlite3.dbapi2 import Cursor

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = os.path.join(BASE_DIR, "data")


FILE_PATH_1 = os.path.join(DATA_DIR, "Тестовый файл1.txt")
FILE_PATH_2 = os.path.join(DATA_DIR, "Тестовый файл2.txt")
JSON_FILE_PATH = os.path.join(DATA_DIR, "output.json")

DB_NAME = "combined_data.db"
TABLE_NAME = "combined_data"


class Encoding(str, Enum):
    UTF_8 = "utf-8"
    ANSI = "ansi"


class FileManager:
    @staticmethod
    def read_file(file_path: str, encoding: str, delimiter: str) -> list[list[str]]:
        data = []
        with open(file_path, encoding=encoding) as file:
            reader = csv.reader(file, delimiter=delimiter)
            for row in reader:
                data.append([item.strip().strip('"') for item in row])
        return data

    @staticmethod
    def save_to_json(data: list[list[str]], output_file: str) -> None:
        with open(output_file, "w", encoding=Encoding.UTF_8) as file:
            json.dump(data, file, ensure_ascii=False, indent=4)

    @staticmethod
    def open_json(json_file_path: str) -> list[list[str]]:
        with open(json_file_path, "r", encoding="utf-8") as file:
            data = json.load(file)
        return data


class DataBaseManager:
    @classmethod
    def save_to_db(cls, data: list[list[str]], db_name: str, table_name: str) -> None:
        with sqlite3.connect(db_name) as conn:
            cursor = conn.cursor()
            cls._create_db_table_if_not_exist(cursor, table_name)

            formated_data = [(item[0], item[1], item[2] if len(item) > 2 else None) for item in data]

            cursor.executemany(f"INSERT INTO {table_name} (column1, column2, column3) VALUES (?, ?, ?)", formated_data)
            conn.commit()

    @staticmethod
    def _create_db_table_if_not_exist(cursor: Cursor, table_name: str) -> None:
        cursor.execute(
            f"""
            CREATE TABLE IF NOT EXISTS {table_name} (
                id INTEGER PRIMARY KEY,
                column1 TEXT,
                column2 TEXT,
                column3 TEXT
            )
        """
        )

    @staticmethod
    def select_all_data(db_name: str, table_name: str) -> list[tuple[str]]:
        with sqlite3.connect(db_name) as conn:
            cursor = conn.cursor()
            cursor.execute(f"SELECT * FROM {table_name}")
            rows = cursor.fetchall()
        return rows

    @classmethod
    def print_all_data(cls, db_name: str, table_name: str) -> None:
        for row in cls.select_all_data(db_name, table_name):
            print(row)


def sort_list_by_2_idx(list: list[list[str]]) -> list[list[str]]:
    return sorted(list, key=lambda x: x[1])


def main() -> None:
    data1 = FileManager.read_file(FILE_PATH_1, Encoding.UTF_8, ",")
    data2 = FileManager.read_file(FILE_PATH_2, Encoding.ANSI, ";")

    sorted_combined_list = sort_list_by_2_idx(data1 + data2)
    FileManager.save_to_json(sorted_combined_list, JSON_FILE_PATH)

    data = FileManager.open_json(JSON_FILE_PATH)
    DataBaseManager.save_to_db(data, DB_NAME, TABLE_NAME)
    DataBaseManager.print_all_data(DB_NAME, TABLE_NAME)


if __name__ == "__main__":
    main()
