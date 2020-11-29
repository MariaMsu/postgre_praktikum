import random
import json
import pandas as pd
import csv
from tqdm import tqdm

random.seed(69)

exam_semester = ("autumn", "spring")
subjects_number = 1_000_000
exam_number = 50_000_000
with open("./input_data/universities.txt") as f_universities, \
        open("./input_data/FirstName.txt") as f_first_name, \
        open("./input_data/LastName.txt") as f_last_name, \
        open("./input_data/enwiki1.json") as f_enwiki1:
    universities = f_universities.read().splitlines()
    first_names = f_first_name.read().splitlines()
    last_names = f_last_name.read().splitlines()
    subjects_and_descriptions = json.load(f_enwiki1)
languages = ["ENG", "GR", "FR"]
lang_prob = [0.7, 0.2, 0.1]

max_university = len(universities)
max_subject_info = len(subjects_and_descriptions)
max_first_name = len(first_names)
max_last_name = len(last_names)

print(f"max_university: {max_university}, max_subject_info: {max_subject_info}")


def fill_subjects_table():
    possible_symbols = \
        set('0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!"#$%&\'()*+,-./:;<=>?@[]^_`{|}~ ')

    def remove_strange_symbols(text):
        text = text.replace("\t", " ").replace("\n", "; ").replace("\\", " ")
        letters = [(x if x in possible_symbols else "") for x in text]
        text = "".join(letters)
        return text

    def handle_body(body_text):
        body_text = body_text#[:100]
        body_text = remove_strange_symbols(body_text)
        return body_text + "..."

    subjects_data = []
    print("subject generation")
    for _ in tqdm(range(subjects_number)):
        subject_info = subjects_and_descriptions[random.randint(0, max_subject_info - 1)]
        subjects_data.append({"university": universities[random.randint(0, max_university - 1)],
                              "subject_name": remove_strange_symbols(subject_info["title"]),
                              "subject_description": handle_body(subject_info["body"]),
                              "schooling_language": random.choices(languages, weights=lang_prob)[0]})

    subjects_df = pd.DataFrame(subjects_data)
    subjects_df.to_csv("./output_data/subjects_table.csv", index=False, sep="\t", header=False)
    print(f"Done subjects_df {len(subjects_df)}")


def fill_exams_table():
    def generate_name():
        f_name = first_names[random.randint(0, max_first_name - 1)]
        l_name = last_names[random.randint(0, max_last_name - 1)]
        return f_name + " " + l_name

    def get_marks(n_marks):
        marks_dict = {}
        for _ in range(n_marks):
            new_name = generate_name()
            while new_name in marks_dict:
                new_name = generate_name()
            marks_dict[new_name] = {"mark": random.randint(1, 10), "attempt_number": random.randint(1, 3)}
        return marks_dict

    def generate_time_subject():
        subject_ind = 1
        year_ind = 2019
        while True:
            if subject_ind > subjects_number:
                subject_ind = 1
                year_ind -= 1
            yield year_ind, exam_semester[random.randint(0, 1)], subject_ind
            subject_ind += 1

    dump_every = 1_000_000
    generator_time_subject = generate_time_subject()
    open("./output_data/exams_table.csv", 'w').close()  # to empty file
    print("exam generation")
    exams_data = []
    for i in tqdm(range(exam_number)):
        marks = get_marks(random.randint(1, 10))
        examiners = [generate_name() for _ in range(random.randint(1, 3))]
        year, semester, subject_id = next(generator_time_subject)
        exams_data.append({"year": year,
                           "semester": semester,
                           "subject_id": subject_id,
                           "marks": json.dumps(marks),
                           "examiners": json.dumps(examiners).replace("[", "{").replace("]", "}")})
        if (i+1) % dump_every == 0:
            exams_df = pd.DataFrame(exams_data)
            exams_df.to_csv("./output_data/exams_table.csv",
                            index=False, sep="\t", header=False, mode='a', quoting=csv.QUOTE_NONE)
            del exams_data
            exams_data = []

    exams_df = pd.DataFrame(exams_data)
    exams_df.to_csv("./output_data/exams_table.csv",
                    index=False, sep="\t", header=False, mode='a', quoting=csv.QUOTE_NONE)
    print(f"Done exams_df {exam_number}")


def fill_university_table():
    def get_phone():
        return "+{0}-({1:03d})-{2:03d}-{3:02d}-{4:02d}".format(
            random.randint(1, 99), random.randint(0, 999), random.randint(0, 999),
            random.randint(0, 99), random.randint(0, 99))

    university_data = []
    for single_university in universities:
        university_data.append({"university": single_university, "phone_number": get_phone()})
    university_df = pd.DataFrame(university_data)
    university_df.to_csv("./output_data/universities_table.csv", index=False, sep="\t", header=False)
    print(f"Done university_df {len(university_df)}")


# fill_university_table()
# fill_subjects_table()
fill_exams_table()
